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
}
