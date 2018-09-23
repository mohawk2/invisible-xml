package XML::Invisible::Receiver;

use strict;
use warnings;
use base 'Pegex::Receiver';

sub gotrule {
  my ($self, $param) = @_;
  return unless defined $param;
  my $parser = $self->{parser};
  my $rule = $parser->{rule};
  my $parentrule = $parser->{parent};
  my ($attr, $flatten) = @{$parentrule}{qw(-wrap -flat)};
  die "Can't have both attribute (+) and flatten (-) on same node"
    if $attr and $flatten;
  if ($flatten) {
    return $param;
  }
  $param = [ $param ] if ref $param ne 'ARRAY';
  $param = $self->flatten($param);
  my %ret = (
    nodename => $rule,
    children => [],
    type => 'element',
    attributes => [],
  );
  for (@$param) {
    if (!ref $_ or $_->{type} eq 'element') {
      push @{ $ret{children} }, $_;
    } elsif ($_->{type} eq 'attr') {
      push @{ $ret{attributes} }, $_->{nodename}, join '', _get_values($_);
    } else {
      die "Unknown entity type '$_->{type}'";
    }
  }
  $ret{type} = 'attr' if $attr;
  \%ret;
}

sub _get_values {
  my ($node) = @_;
  map ref($_) ? _get_values($_) : $_, @{ $node->{children} };
}

1;

__END__
=head1 NAME

XML::Invisible::Receiver - XML::Invisible Pegex AST constructor

=head1 SYNOPSIS

  my $grammar = Pegex::Grammar->new(text => $grammar_text);
  my $parser = Pegex::Parser->new(
    grammar => $grammar,
    receiver => XML::Invisible::Receiver->new,
  );
  my $got = $parser->parse($ixml_text);

=head1 DESCRIPTION

Subclass of L<Pegex::Receiver> to turn Pegex parsing events into data
usable by L<XML::Invisible>.

The AST returned represents an XML document with a hash-ref with these keys:

=over

=item nodename

=item attributes

An array-ref with pairs of name, value (in order to preserve ordering).

=item children

An array-ref of child nodes. If the node is a simple scalar, it is a
text node.

=item type

This will be C<element> at the top level.

=back

=cut