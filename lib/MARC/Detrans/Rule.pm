package MARC::Detrans::Rule;

use strict;
use warnings;
use Carp qw( croak );

=head1 NAME

MARC::Detrans::Rule

=head1 SYNOPSIS

    use MARC::Detrans::Rule;
    
    my $rule = MARC::Detrans::Rule->new( 
        from    => 'b', 
        to      => 'B',
        escape  => '(B'
    );

=head1 DESCRIPTION

It's unlikely that you'll want to use MARC::Detrans::Rule directly since
other modules wrap access to it. Each detransliteration rule is represented 
as a MARC::Detrans::Rule object, which basically provides the Romanized text
and the corresponding MARC-8 or UTF-8 text, along with an escape character
(for MARC-8) rules.

=head1 METHODS

=head2 new()

=cut

sub new {
    my ( $class, %opts ) = @_;
    croak( "must supply 'from' parameter" ) if ! exists( $opts{from} );
    croak( "must supply 'to' parameter" ) if ! exists( $opts{to} );
    return bless \%opts, ref($class) || $class;
}

=head2 from()

Returns the Romanized text that this rule refers to.

=cut

sub from {
    return shift->{from};
}

=head2 to()

Returns the MARC-8 or UTF-8 text that the corresponding Romanized text should
be converted to.

=cut

sub to {
    return shift->{to};
}

=head2 escape() 

Returns a MARC-8 character set escape sequence to be used, or undef if the rule
is for an UTF-8 mapping.

=cut

sub escape {
    return shift->{escape};
}

=head1 AUTHORS

=over 4

=item * Ed Summers <ehs@pobox.com>

=back

=cut

1;
