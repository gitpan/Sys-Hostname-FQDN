#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* gethostname	*/
#include <unistd.h>

/* inet_ntoa	*/
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* from /usr/include/arpa/nameser.h	*/
#define NS_MAXDNAME	1025	/* maximum domain name */

static int
my_inet_aton(register const char *cp, struct in_addr *addr)
{
	dTHX;
	register U32 val;
	register int base;
	register char c;
	int nparts;
	const char *s;
	unsigned int parts[4];
	register unsigned int *pp = parts;

       if (!cp || !*cp)
		return 0;
	for (;;) {
		/*
		 * Collect number up to ``.''.
		 * Values are specified as for C:
		 * 0x=hex, 0=octal, other=decimal.
		 */
		val = 0; base = 10;
		if (*cp == '0') {
			if (*++cp == 'x' || *cp == 'X')
				base = 16, cp++;
			else
				base = 8;
		}
		while ((c = *cp) != '\0') {
			if (isDIGIT(c)) {
				val = (val * base) + (c - '0');
				cp++;
				continue;
			}
			if (base == 16 && (s=strchr(PL_hexdigit,c))) {
				val = (val << 4) +
					((s - PL_hexdigit) & 15);
				cp++;
				continue;
			}
			break;
		}
		if (*cp == '.') {
			/*
			 * Internet format:
			 *	a.b.c.d
			 *	a.b.c	(with c treated as 16-bits)
			 *	a.b	(with b treated as 24 bits)
			 */
			if (pp >= parts + 3 || val > 0xff)
				return 0;
			*pp++ = val, cp++;
		} else
			break;
	}
	/*
	 * Check for trailing characters.
	 */
	if (*cp && !isSPACE(*cp))
		return 0;
	/*
	 * Concoct the address according to
	 * the number of parts specified.
	 */
	nparts = pp - parts + 1;	/* force to an int for switch() */
	switch (nparts) {

	case 1:				/* a -- 32 bits */
		break;

	case 2:				/* a.b -- 8.24 bits */
		if (val > 0xffffff)
			return 0;
		val |= parts[0] << 24;
		break;

	case 3:				/* a.b.c -- 8.8.16 bits */
		if (val > 0xffff)
			return 0;
		val |= (parts[0] << 24) | (parts[1] << 16);
		break;

	case 4:				/* a.b.c.d -- 8.8.8.8 bits */
		if (val > 0xff)
			return 0;
		val |= (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8);
		break;
	}
	addr->s_addr = htonl(val);
	return 1;
}

MODULE = Sys::Hostname::FQDN	PACKAGE = Sys::Hostname::FQDN

PROTOTYPES: DISABLE

void
usually_short()
    PREINIT:
	SV * out;
	char local_name[NS_MAXDNAME];
    PPCODE:
	if (gethostname(local_name,NS_MAXDNAME) != 0) {
	  ST(0) = &PL_sv_undef;
	}
	else {
	  out = sv_newmortal();
	  out = newSVpv(local_name,0);
	  ST(0) = out;
	}
	XSRETURN(1);

void
inet_ntoa(netaddr)
	SV * netaddr
    PREINIT:
	STRLEN len;
	SV * out;  
	union {    
	    struct in_addr * inadr;
	    char * addr;
	} naddr;
    PPCODE:
	naddr.addr = (unsigned char *)(SvPV(netaddr, len));
	out = sv_newmortal();
	out = newSVpv(inet_ntoa(*naddr.inadr),0);
	ST(0) = out;
	XSRETURN(1);

void
inet_aton(dotquad)
	SV * dotquad
    PREINIT:
	SV * out;
	STRLEN len;
	unsigned char * dq;
	union {
	    struct in_addr * inadr;
	    char * addr;
	} naddr;
    PPCODE:
	dq = (unsigned char *)(SvPV(dotquad, len));
	my_inet_aton(dq,naddr.inadr);
	out = sv_newmortal();
	out = newSVpv(naddr.addr,4);
	ST(0) = out;
	XSRETURN(1);
