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

The location to write out the new records. If unspecified log messages
will be sent to STDOUT.

=item * --log

Optional parameter to log messages to a file rather than the screen.

=back

=cut

## gather options or output documentation
my ( $config, $in, $out, $log ); 
GetOptions(
    'config=s'      => \$config,
    'in=s'          => \$in,
    'out=s'         => \$out,
    'log=s'         => \$log,
);
pod2usage( {verbose=>2} ) if ! ($config and $in and $out);

## create our detransliteration engine
my $detrans = MARC::Detrans->new( config => $config );

## open up some MARC records
my $batch = MARC::Batch->new( 'USMARC', $in );
open( OUT, ">$out" );

## redirect to log if necessary
if ( $log ) { open( LOG, ">$log" ); }
else { *LOG = *STDOUT; }

## setup some counters
my $recordCount = 0;
my $errorCount = 0;

while ( my $record = $batch->next() ) {
    $recordCount++;
    my $new = $detrans->convert( $record );

    ## print out any errors 
    foreach ( $detrans->errors() ) {
        $errorCount++;
        print LOG "record $recordCount: $_\n";
    }

    ## output the new record
    print OUT $new->as_usmarc();
}

## output summary stats

print LOG "\n\nJOB STATISTICS\n\n";
printf LOG "%-17s%10d\n", 'Records Processed', $recordCount;
printf LOG "%-17s%10d\n", '880 Fields Added', $detrans->stats880sAdded();
printf LOG "%-17s%10d\n", 'Errors', $errorCount;

## statsDetransliterated() returns a hash of statistics
## for which field/subfield combinations were transliterated
## we will just output them in sorted order
my %transCounts = $detrans->statsDetransliterated();
my @sorted = sort { $transCounts{$b} <=> $transCounts{$a} } keys(%transCounts);
print LOG "\nFields/Subfields Transliterated: \n";
foreach ( @sorted ) {
    printf LOG "%17s%10d\n", $_, $transCounts{ $_ };
}

## statsCopied retuns a similar has of statistics
## for which field/subfield combinations were copied
## we will just output them in sorted order
my %copyCounts = $detrans->statsCopied();
@sorted = sort { $copyCounts{$b} <=> $copyCounts{$a} } keys(%copyCounts);
print LOG "\nFields/Subfields Copied: \n";
foreach ( @sorted ) {
    printf LOG "%17s%10d\n", $_, $copyCounts{ $_ };
}

print LOG "\n\n";

