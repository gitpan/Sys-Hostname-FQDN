package Sys::Hostname::FQDN;

#use 5.006;
use strict;
#use warnings;
use Carp;

use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

require Exporter;
require DynaLoader;
use AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw (
	asciihostinfo
	gethostinfo
	inet_ntoa
	inet_aton
	fqdn
	short
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined FQDN macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Sys::Hostname::FQDN $VERSION;

# Preloaded methods go here.

sub DESTROY {};

# Autoload methods go after =cut, and are processed by the autosplit program.

sub short {
  return (split(/\./,&usually_short))[0];
}

sub fqdn {
  return (gethostbyname(&usually_short))[0];
}

sub gethostinfo {
  return gethostbyname(&usually_short);
}

sub asciihostinfo {
  my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname(&usually_short);
  for(0..$#addrs) {
    $addrs[$_] = inet_ntoa($addrs[$_]);
  }
  return ($name,$aliases,$addrtype,$length,@addrs);
}

1;
__END__

=head1 NAME

  Sys::Hostname::FQDN

=head1 SYNOPSIS

  use Sys::Hostname::FQDN qw(
	asciihostinfo
	gethostinfo
	inet_ntoa
	inet_aton
	fqdn
	short
  );

  $host = short();
  $fqdn = fqdn();
  ($name,$aliases,$addrtype,$length,@addrs)=gethostinfo();
  ($name,$aliases,$addrtype,$length,@addrs)=asciihostinfo();
  $dotquad = inet_ntoa($netaddr);
  $netaddr = inet_aton($dotquad);

=head1 INSTALLATION

To install this module type the following:

  perl Makefile.PL
  make
  make test
  make install

=head1 DESCRIPTION

B<Sys::Hostname::FQDN> uses the host 'C' library to discover the (usually)
short host name, then uses (perl) gethostbyname to extract the real
hostname. 

The results from gethostbyname are exported as B<gethostinfo> and
B<asciihostinfo> as a convenience since they are available. Similarly, the
'C' library functions B<inet_ntoa> and B<inet_aton> are exported.

=over 4

=item $host = short();

  returns the host part of this host's FQDN.

=item $fqdn = fqdn();

  returns the fully qualified host name of this host.

=item ($name,$aliases,$addrtype,$length,@addrs)=gethostinfo();

  returns:
    $name	fully qualifed host name of this host.
    $aliases	alternate names for this host.
    $addrtype	The type of address; always AF_INET at present.
    $length	The length of the address in bytes.
    @addrs	array of network addresses for this host 
		in network byte order.

=item ($name,$aliases,$addrtype,$length,@addrs)=asciihostinfo();

  returns:
    $name	fully qualifed host name of this host.
    $aliases	alternate names for this host.
    $addrtype	The type of address; always AF_INET at present.
    $length	The length of the address in bytes.
    @addrs	array of dot quad IP addresses for this host.

=item $dotquad = inet_ntoa($netaddr);

  input:	packed network address in network byte order.
  returns:	dot quad IP address.

=item $netaddr = inet_aton($dotquad);

  input:	dot quad IP address.
  returns:	packed network address in network byte order.

=back

=head1 DEPENDENCIES

  none

=head1 EXPORT

  None by default

=head1 EXPORT_OK

  asciihostinfo
  gethostinfo
  inet_ntoa
  inet_aton
  fqdn
  short

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT AND LICENCE

  Copyright 2003, Michael Robinton <michael@bizsystems.com>
 
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 

=cut
