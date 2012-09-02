package Serializer;

our $VERSION = '0.01';


=head1 NAME

Serializer - lightweight perl serializer

=head1 SYNOPSIS

    use Serializer qw(thaw freeze);
    
    my $frozen = freeze ([1, 2, 3]);
    my $unfrozen = thaw ($frozen);

=head1 DESCRIPTION

Simple lightweight recursive pure-perl data serializer. Takes into account
UTF-8 scalars. Works just like thaw() and freeze() in L<Storable>.

=head1 EXPORT

Doesn't export anything by default.

=cut

use strict;
use warnings;
no  warnings 'uninitialized';
use bytes;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(freeze thaw);

use Carp;

sub freeze ($);
sub thaw ($);


sub freeze_scalar {
    if (defined $_[0]) {
        if (utf8::is_utf8 ($_[0])) {
            "U".length ($_[0]) .":". $_[0]
        } else {
            "P".length ($_[0]) .":". $_[0]
        }
    } else {
        "N"  # undef
    }
}

sub freeze_arrayref {
    my $buf = "A". scalar (@{$_[0]}) ."[";
    foreach (@{$_[0]}) {
        $buf .= freeze ($_);
    }
    $buf .= "]";
    $buf;
}

sub freeze_hashref {
    my $buf = "H". scalar (keys %{$_[0]}) ."{";
    while (my ($key, $value) = each %{$_[0]}) {
        $buf .= freeze ($key);
        $buf .= freeze ($value);
    }
    $buf .= "}";
    $buf;
}

sub freeze ($) {
    if (ref $_[0] eq '') {
        &freeze_scalar;
    } elsif (ref $_[0] eq 'ARRAY') {
        &freeze_arrayref;
    } elsif (ref $_[0] eq 'HASH') {
        &freeze_hashref;
    } elsif (ref $_[0] eq 'SCALAR') {
        "\\". freeze_scalar (${$_[0]});
    } elsif (ref $_[0] eq 'REF') {
        "\\". freeze (${$_[0]});
    } else {
        croak "Cannot freeze reftype ". ref ($_[0]);
    }
}


sub thaw_scalar {
    if ($_[0] =~ /\G ([0-9]{1,7}) \:/gcsx) {
        my $len = $1;
        pos ($_[0]) += $len;
        substr ($_[0], pos ($_[0]) - $len, $len); 
    } else {
        croak "Incorrectly encoded scalar ".
              "at pos ". pos ($_[0]) .": '". 
                substr ($_[0], pos($_[0]), 10) ."'";
    }
}

sub thaw_arrayref {
    if ($_[0] =~ /\G ([0-9]{1,6}) \[/gcsx) {
        my $len = $1;
        my $arrayref = [];
        for (my $i = 0; $i < $len; $i++) {
            push @$arrayref, &thaw;
        }

        if ($_[0] =~ /\G \]/gcsx) {
            $arrayref;
        } else {
            croak "Incorrectly encoded arrayref's ending ".
                  "at pos ". pos ($_[0]) .": '". 
                    substr ($_[0], pos($_[0]), 10) ."'";
        }
    } else {
        croak "Incorrectly encoded arrayref ".
              "at pos ". pos ($_[0]) .": '". 
                substr ($_[0], pos($_[0]), 10) ."'";
    }
}

sub thaw_hashref {
    if ($_[0] =~ /\G ([0-9]{1,6}) \{/gcsx) {
        my $len = $1;
        my $hashref = {};
        for (my $i = 0; $i < $len; $i++) {
            my $key = &thaw;
            $hashref->{$key} = &thaw;
        }

        if ($_[0] =~ /\G \}/gcsx) {
            $hashref;
        } else {
            croak "Incorrectly encoded hashref's ending ".
                  "at pos ". pos ($_[0]) .": '". 
                    substr ($_[0], pos($_[0]), 10) ."'";
        }
    } else {
        croak "Incorrectly encoded hashref ".
              "at pos ". pos ($_[0]) .": '". 
                substr ($_[0], pos($_[0]), 10) ."'";
    }
}

sub thaw ($) {
    if ($_[0] =~ /\G ([PUNHA\\])/gcsx) {
        if ($1 eq 'P') {
            &thaw_scalar;
        } elsif ($1 eq 'U') {
            my $scalar = &thaw_scalar;
            utf8::upgrade ($scalar);
            $scalar;
        } elsif ($1 eq 'N') {
            undef;
        } elsif ($1 eq 'H') {
            &thaw_hashref;
        } elsif ($1 eq 'A') {
            &thaw_arrayref;
        } elsif ($1 eq '\\') {
            my $value = &thaw;
            \$value;
        }
    } else {
        croak "Unknown element type ".
              "at pos ". (pos ($_[0]) || 0) .": '". 
                substr ($_[0], pos($_[0]), 10) ."'";
    }
}


=head1 SEE ALSO

L<Storable>, L<JSON::XS>, L<Data::MessagePack>

=head1 AUTHOR

Alexandr Gomoliako <zzz@zzz.org.ua>

=head1 LICENSE

Copyright 2012 Alexandr Gomoliako. All rights reserved.

This module is free software. It may be used, redistributed and/or modified 
under the same terms as Perl itself.

=cut

1;
