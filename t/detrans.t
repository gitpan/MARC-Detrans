use strict;
use warnings;
use Test::More qw( no_plan );
use Test::Exception;

use_ok( 'MARC::Detrans' );
use_ok( 'MARC::Batch' );

my $detrans = MARC::Detrans->new( config => 't/testconfig.xml' );
isa_ok( $detrans, 'MARC::Detrans' );

throws_ok { MARC::Detrans->new() } qr/must supply config parameter/, 
    'no config in constructor call';

throws_ok { MARC::Detrans->new( config => 'foo' ) } 
    qr/config file doesn't exist/,
    'non-existent xml config file'; 

my $batch = MARC::Batch->new( 'USMARC', 't/marc.dat' );
while ( my $record = $batch->next() ) {
    $record = $detrans->convert( $record );
    if ( !$record ) { print $detrans->error(); next; }
    isa_ok( $record, 'MARC::Record' );
    ok( $record->field( '880' ), 'found 880 fields' );
    ok( $record->field( '066' ), 'found 066 field' );

    ## look at 880 and try to find original field and look for subfield
    ## 6 in it.
    foreach my $field ( $record->field( '880' ) ) {
        my $sub6 = $field->subfield(6);
        my ( $tag, $ocurrence ) = split /-/, $sub6;
        my @fields = $record->field( $tag );
        my $f = $fields[$ocurrence-1];
        ok( $f->subfield('6'), 'found subfield 6 in original field' );
    }
}
