package MARC::Detrans;

use strict;
use warnings;
use Carp qw( croak );
use MARC::Detrans::Config;

our $VERSION = '0.6';

=head1 NAME

MARC::Detrans - De-transliterate text and MARC records

=head1 SYNOPSIS

    use MARC::Batch;
    use MARC::Detrans;

    my $batch = MARC::Batch->new( 'marc.dat' );
    my $detrans = MARC::Detrans->new( 'config.xml' );

    while ( my $record = $batch->next() ) {
        my $newRecord = $detrans->convert( $record );
    }

=head1 DESCRIPTION

MARC::Detrans is an eclectic addition to the already eclectic MARC::Record
distribution for de-transliterating MARC::Records. What is detransliteration
you ask? As you might have guessed it's the opposite of transliteration, which
according to the Merriam-Webster:

    to represent or spell in the characters of another alphabet

Traditionally when librarians catalog an item that has a title in a non-Roman 
script they will follow transliteration rules for converting the title
into the Roman alphabet, so that the bibliographic record could be filed
into the card catalog or database index appropriately. These Romanization 
Rules are published by the Library of Congress 
http://www.loc.gov/catdir/cpso/roman.html.

Now that computer screens can display Unicode fairly well it is now 
desirable to display the original script for library users who are 
more familiar with the original script. MARC::Detrans provides a framework 
for detransliterating MARC records so that the orginal script is available 
MARC-8 encoded in 880 fields.  Very esoteric right?

=head1 CONFIGURATION 

MARC::Detrans behavior is controlled by an XML configuration file. An 
example of this configuration file can be found in the examples directory
of the MARC::Detrans distribution. The configuration determines the 
detransliteration rules that will be used to add 880 fields to existing 
records. It is hoped that people will contribute their configurations 
for various languages to the MARC::Detrans project so that they can 
be distributed with this package. For more information about the 
configuration file see L<MARC::Detrans::Config>.

In addition a sample driver program which uses MARC::Detrans has also 
been included in the examples directory. This script is meant as a 
jumping off point showing how to use the MARC::Detrans framework.

=head1 METHODS

=head2 new()

The constructor which you should pass the path to your configuration file.

    my $detrans = MARC::Detrans->new(  config => 'config.xml' );

=cut

sub new {
    my ($class,%args) = @_;
    croak( "must supply config parameter" ) if ! exists $args{config};
    croak( "config file doesn't exist" ) if ! -f $args{config};
    my $config = MARC::Detrans::Config->new( $args{config} );
    my $self = { config => $config, errors => [] }; 
    return bless $self, ref($class) || $class;
}

=head2 convert()

Pass a MARC::Record into convert() and you will be returned a 
new MARC::Record with portions of it modified according to your
configuration file. 

IMPORTANT: you'll probably want to call errors() afterwards to 
see if there were any problems during the conversion.

=cut

sub convert {
    my ($self,$record) = @_;
    croak( "must pass in MARC::Record object" ) 
        if ! ref($record) or ! $record->isa( 'MARC::Record' );
    my $config = $self->{config};

    ## check the language of the record
    my $f008 = $record->field( '008' );
    if ( ! $f008 ) { 
        $self->addError( "can't determine language in record: missing 008" );
        return $record;
    }
    my $lang = substr( $f008->data(), 35, 3 );
    if ( $lang ne $config->languageCode() ) {
        $self->addError( "record is not correct language: $lang instead of ". 
            $config->languageCode() ); 
        return $record;
    }

    ## add 880 fields
    $self->add880s( $record );
    return $record;
}

## internal helper for adding 880 fields to a record.

sub add880s {
    my ($self,$r) = @_;
    my $config = $self->{config};
    my $rules = $config->rules();
    my $names = $config->names();
    my %seen = ();
    my $edited = 0;

    foreach my $tag ( $config->detransFields() ) {
        FIELD: foreach my $field ( $r->field($tag) ) { 
            my @newSubfields = ();
    
            if ( isNameField($tag) ) {
                my $nameData = $names->convert( $field );
                if ( $nameData ) {
                    add880( $r, \%seen, $field, $nameData );
                    $edited = 1;
                    next FIELD;
                }
            }

            SUBFIELD: foreach my $subfield ( $field->subfields() ) { 
                my ($code,$data) = @$subfield;
                if ($config->needsDetrans(field=>$tag,subfield=>$code)) {
                    my $new = $rules->convert( $data );
                    if ( ! defined $new ) {
                        $self->addError( "field=$tag subfield=$code: " .
                            $rules->error() );
                        next FIELD;
                    }
                    push( @newSubfields, $code, $rules->convert($data) );
                }
                elsif ($config->needsCopy(field=>$tag,subfield=>$code)) {
                    push( @newSubfields, $code, $data);
                }
            }

            if ( @newSubfields ) {
                add880( $r, \%seen, $field, \@newSubfields );
                $edited = 1;
            }
        }

    }

    if ( $edited ) {
        $self->add066($r);
    }

}

sub isNameField {
    my $tag = shift;
    return grep /^$tag$/, qw( 100 110 600 700 810 800 );
}

## private helper function to add a single 880 based on the
## tag and indicators of another field

sub add880 {
    my ( $record, $seen, $field, $subfields ) = @_;
    my $tag = $field->tag();
    my $occurrence = sprintf( '%02d', ++$seen->{ $tag } );
    my $f880 = MARC::Field->new(
        '880',
        $field->indicator(1),
        $field->indicator(2),
        6, "$tag-$occurrence",   ## subfield 6
        @$subfields              ## the reset of the subfields
    );
    $record->insert_grouped_field( $f880 );
}

## private helper function for adding a 066 indicating which 
## additional character sets were used in this record

sub add066 {
    my ($self,$record) = @_;
    my $config = $self->{config};

    ## get a list of all the 066 fields used in this mapping
    ## techically we should probably only list here the ones
    ## that are *actually* used in this record...but there's
    ## probably no harm in listing all of the ones used in this
    ## configuration.
    my @subfields;
    foreach ( $config->allEscapeCodes() ) {
        push( @subfields, 'c', $_ );
    }

    ## don't obliterate an 066 that's already present
    my $f066 = $record->field( '066' );
    if ( $f066 ) { 
        unshift( @subfields, map { $_->[0], $_->[1] } $f066->subfields() );
        my $new066 = MARC::Field->new( '066', '', '', @subfields );
        $f066->replace_with( $new066 );
    } else {
        $f066 = MARC::Field->new( '066', '', '', @subfields );
        $record->insert_grouped_field( $f066 );
    }
}

=head2 errors()

Will return the latest errors encountered during a call to convert(). Can
be useful for determining why a call to convert() returned undef. A side 
effect of calling errors() is that the errors storage is reset.

=cut

sub errors {
    my $self = shift;
    my @errors = @{ $self->{errors} };
    $self->{errors} = [];
    return @errors;
}

## this really should just be used internally...hence no POD
sub addError {
    my ($self,$msg) = @_;
    push( @{ $self->{errors} }, $msg );
}

=head1 AUTHORS

MARC::Detrans was developed as part of a project funded by the Queens 
Borough Public Library in New York City under the direction of Jane Jacobs. 

=over 4

=item * Ed Summers <ehs@pobox.com>

=back

=cut

1;
