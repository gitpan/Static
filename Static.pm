package Tie::Static;
$VERSION = 0.01;

foreach my $type (qw(Hash Array Scalar)) {
  my $meth = uc($type);
  eval qq(
    package Tie::Static::$type;
    require Tie::$type;
    \@ISA = 'Tie::Std$type';
    
    sub TIE$meth {
      my \$class = shift;
      my \$id = join "|", caller(), \@_;
      return \$preserved{\$id}
        ||= \$class->SUPER::TIE$meth();
    }
    
    sub Tie::Static::TIE$meth {
      shift;
      unshift \@_, 'Tie::Static::$type';
      goto &Tie::Static::$type\::TIE$meth;
    }
    
  ) or die $@;
}

1;

__END__

=head1 NAME

Tie::Static - create static lexicals

=head1 SYNOPSIS

  use Tie::Static;
  
  sub foo {
    tie (my $static_scalar, 'Tie::Static');
    tie (my @static_array, 'Tie::Static');
    tie (my %static_hash, 'Tie::Static');
    # do whatever you want
  }

=head1 DESCRIPTION

This module makes it easy to produce static variables.

A static variable is a variable whose value will remain
constant from invocation to invocation.  The usual way
to produce this is to create an enclosing scope which
contains a lexically scoped variable.  For instance the
example above could be written as:

  {
    my $static_scalar;
    my @static_array;
    my %static_hash;
    
    sub foo {
      # Do whatever you want
    }
  }

But while this works, many people find it cumbersome
to have to produce new scopes manually just to get a
static variables.  This module provides an alternate
solution by providing a way to tie lexical variables
back to the same value each time.

As an additional feature, this module supports "modal
statics".  If you pass additional arguments into the
tie, those arguments will be factored into the
decision of what static you get.

=head1 BUGS

This module uses the feedback from I<caller> to decide
what static to give you back.  While this is good
enough for most possible uses of statics, it is not
always right.  Aside from the possibility of someone
deliberately confusing I<caller>, closures will not,
in general, be distinguished from each other since
two instances will have the same package, filename,
and line number.  You might argue that it is easy
enough to solve that by passing in a unique lexically
scoped variable as a mode.  And it is.  But in that
case the lexical that is your mode is already a static
and it would usually make more sense to create more
lexicals in that scope.

This only allows static scalars, arrays, and hashes.

If you want to overload the implementation of a static,
please note that scalars, arrays, and hashes are not
tied to the package Tie::Static.  Instead they are tied
to the private packages Tie::Static::Scalar,
Tie::Static::Array, and Tie::Static::Hash.

=head1 AUTHOR AND COPYRIGHT

Ben Tilly (ben_tilly@operamail.com)

Copyright 2001.  This may be modified and distributed
on the same terms as Perl.
