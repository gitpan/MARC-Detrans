#!/usr/bin/perl

use strict;
use warnings;

use MARC::Detrans;
use MARC::Batch;
use Getopt::Long;
use Pod::Usage;

=head1 NAME

convert.pl - a sample MARC::Detrans driver

=head1 SYNOPSIS
    
    convert.pl --config=options.xml --in=marc.dat --out=new.dat

=head1 DESCRIPTION

This is a sample script that illustrates how to use MARC::Detrans
for detransliterating MARC records.

=head1 OPTIONS

=over 4

=item * --config

The location of the XML config file.

=item * --in

The location of the MARC input file.

=item * --out

The location to write out the new records.

=back

=cut

## gather options or output documentation
my ( $config, $in, $out ); 
GetOptions(
    'config=s'      => \$config,
    'in=s'          => \$in,
    'out=s'         => \$out,
);
pod2usage( {verbose=>2} ) if ! ($config and $in and $out);

my $detrans = MARC::Detrans->new( config => $config );
my $batch = MARC::Batch->new( 'USMARC', $in );
open( OUT, ">$out" );
my $count = 0;

while ( my $record = $batch->next() ) {
    $count++;
    my $new = $detrans->convert( $record );

    ## print out any errors 
    foreach ( $detrans->errors() ) {
        print STDERR "record $count: $_\n";
    }

    ## output the new record
    print OUT $new->as_usmarc();
}


