#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* gethostname	*/
#include <unistd.h>

/* inet_ntoa	*/
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <resolv.h>

/* from /usr/include/arpa/nameser.h	*/
#define NS_MAXDNAME	1025	/* maximum domain name */

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
	inet_aton(dq,naddr.inadr);
	out = sv_newmortal();
	out = newSVpv(naddr.addr,4);
	ST(0) = out;
	XSRETURN(1);
