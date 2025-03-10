%{

/*
 * Copyright (c) 2007,2008,2009,2010 Mij <mij@sshguard.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/*
 * SSHGuard. See http://www.sshguard.net
 */

#include <string.h>

#include "parser.h"

#define DEFAULT_ATTACKS_DANGEROUSNESS           10

 /* stuff exported by the scanner */
extern void scanner_init();
extern void scanner_fin();
extern int yylex();

static void yyerror(attack_t *, const char *);

%}

%parse-param { attack_t *attack }

/* %pure-parser */
%start text

%union {
    char *str;
    int num;
}

/* semantic values for tokens */
%token <str> IPv4 IPv6 HOSTADDR WORD
%token <num> INTEGER SYSLOG_BANNER_PID SOCKLOG_BANNER_PID BUSYBOX_SYSLOG_BANNER_PID

/* flat tokens */
%token SYSLOG_BANNER TIMESTAMP_SYSLOG TIMESTAMP_ISO8601 TIMESTAMP_TAI64 AT_TIMESTAMP_TAI64 RFC_5234_BANNER METALOG_BANNER SOCKLOG_BANNER
%token REPETITIONS
%token HTTP_REQUEST HTTP_VERSION HTTP_REDIRECT HTTP_AUTHFAIL HTTP_CLIERROR
%token HTTP_BOTSEARCH_WEBMAIL HTTP_BOTSEARCH_PHPMYADMIN HTTP_BOTSEARCH_WORDPRESS HTTP_BOTSEARCH_JOOMLA HTTP_BOTSEARCH
/* ssh */
%token SSH_INVALUSERPREF SSH_NOTALLOWEDPREF SSH_NOTALLOWEDSUFF
%token SSH_LOGINERR_PREF SSH_LOGINERR_PAM
%token SSH_VIA
%token SSH_MAXAUTH
%token SSH_ADDR_SUFF
%token SSH_NOIDENTIFSTR SSH_BADPROTOCOLIDENTIF SSH_BADPROTOCOLIDENTIF_SUFF
%token SSH_INVALIDFORMAT_PREF SSH_INVALIDFORMAT_SUFF
%token SSH_BADKEX_PREF SSH_BADKEX_SUFF
%token SSH_DISCONNECT_PREF SSH_CONNECTION_CLOSED SSH_PREAUTH_SUFF
/* SSHGuard */
%token SSHGUARD_ATTACK_PREF SSHGUARD_ATTACK_SUFF
%token SSHGUARD_BLOCK_PREF SSHGUARD_BLOCK_SUFF
/* BIND */
%token BIND_PREF BIND_QUERY_DENIED
/* dovecot */
%token DOVECOT_IMAP_LOGINERR_PREF DOVECOT_IMAP_LOGINERR_SUFF
/* uwimap */
%token UWIMAP_LOGINERR
/* cyrus-imap */
%token CYRUSIMAP_SASL_LOGINERR_PREF CYRUSIMAP_SASL_LOGINERR_SUFF
/* cucipop */
%token CUCIPOP_AUTHFAIL
/* exim */
%token EXIM_ESMTP_AUTHFAIL_PREF EXIM_ESMTP_AUTHFAIL_SUFF
%token EXIM_ESMTP_LOGINFAIL_PREF EXIM_ESMTP_LOGINFAIL_SUFF
/* sendmail */
%token SENDMAIL_RELAYDENIED_PREF SENDMAIL_RELAYDENIED_SUFF
%token SENDMAIL_AUTHFAILURE_PREF SENDMAIL_AUTHFAILURE_SUFF
/* postfix */
%token POSTFIX_NO_AUTH_PREF POSTFIX_SASL_LOGINERR_PREF POSTFIX_SASL_LOGINERR_SUFF
%token POSTFIX_NONSMTP POSTFIX_NONSMTP_SUFF
%token POSTFIX_GREYLIST POSTFIX_GREYLIST_SUFF
%token POSTSCREEN_PREF POSTSCREEN_SUFF
/* FreeBSD's FTPd */
%token FREEBSDFTPD_LOGINERR_PREF FREEBSDFTPD_LOGINERR_SUFF
/* proFTPd */
%token PROFTPD_LOGINERR_PREF PROFTPD_LOGINERR_SUFF
/* PureFTPd */
%token PUREFTPD_LOGINERR_PREF PUREFTPD_LOGINERR_SUFF
/* vsftpd */
%token VSFTPD_LOGINERR_PREF VSFTPD_LOGINERR_SUFF
/* cockpit */
%token COCKPIT_AUTHFAIL_PREF COCKPIT_AUTHFAIL_SUFF
/* CLF request */
%token CLF_REQUEST_PREF
/* CLF, unauhtorized */
%token CLF_UNAUTHOIRIZED_PREF CLF_UNAUTHOIRIZED_SUFF
/* CLF, common webapp probes */
%token CLFWEBPROBES_BOTSEARCH_SUFF
/* CLF, common CMS frameworks brute-force attacks */
%token CLF_LOGIN_URL_SUFF
/* OpenSMTPD */
%token OPENSMTPD_FAILED_CMD_PREF OPENSMTPD_AUTHFAIL_SUFF OPENSMTPD_UNSUPPORTED_CMD_SUFF
/* courier */
%token COURIER_AUTHFAIL_PREF
/* OpenVPN */
%token OPENVPN_TLS_ERR_SUFF
/* Gitea */
%token GITEA_ERR_PREF GITEA_ERR_SUFF
/* OpenVPN Portshare */
%token OPENVPN_PS_TERM_PREF
%token OPENVPN_PS_TERM_SUFF
/* MSSQL */
%token MSSQL_AUTHFAIL_PREF
/* Proxmox VE */
%token PROXMOXVE_AUTHFAIL_PREF PROXMOXVE_AUTHFAIL_SUFF

%%

/* log source */
text:
    log_prefix msg_single repetition_suffix
  | msg_single
  ;

log_prefix:
    syslogent
  | multilogent
  | RFC_5234_BANNER
  | metalogent
  | socklogent
  | busyboxent
  ;

/* a syslog-generated log entry */
syslogent:
    SYSLOG_BANNER
  | SYSLOG_BANNER_PID      /* timestamp hostname procname[pid]: logmsg */
  | TIMESTAMP_ISO8601      /* some have different timestamps */
  | TIMESTAMP_ISO8601 WORD /* handle different timestamp with proc name */
  ;

/* a multilog-generated log entry */
multilogent:
    AT_TIMESTAMP_TAI64
  ;

metalogent:
    METALOG_BANNER
  ;

/* a socklog-generated log entry */
socklogent:
    SOCKLOG_BANNER
  | SOCKLOG_BANNER_PID
  ;

/* a busybox syslog log entry */
busyboxent:
    BUSYBOX_SYSLOG_BANNER_PID
  ;

repetition_suffix:
    /* epsilon */
  | REPETITIONS
  ;

msg_single:
    sshmsg            { attack->service = SERVICES_SSH; }
  | sshguardmsg       { attack->service = SERVICES_SSHGUARD; }
  | bindmsg           { attack->service = SERVICES_BIND; }
  | dovecotmsg        { attack->service = SERVICES_DOVECOT; }
  | uwimapmsg         { attack->service = SERVICES_UWIMAP; }
  | cyrusimapmsg      { attack->service = SERVICES_CYRUSIMAP; }
  | cucipopmsg        { attack->service = SERVICES_CUCIPOP; }
  | eximmsg           { attack->service = SERVICES_EXIM; }
  | sendmailmsg       { attack->service = SERVICES_SENDMAIL; }
  | postfixmsg        { attack->service = SERVICES_POSTFIX; }
  | freebsdftpdmsg    { attack->service = SERVICES_FREEBSDFTPD; }
  | proftpdmsg        { attack->service = SERVICES_PROFTPD; }
  | pureftpdmsg       { attack->service = SERVICES_PUREFTPD; }
  | vsftpdmsg         { attack->service = SERVICES_VSFTPD; }
  | cockpitmsg        { attack->service = SERVICES_COCKPIT; }
  | clfunauhtdmsg     { attack->service = SERVICES_CLF_UNAUTH; }
  | clfwebprobesmsg   { attack->service = SERVICES_CLF_PROBES; }
  | clfcmsmsg         { attack->service = SERVICES_CLF_LOGIN_URL; }
  | opensmtpdmsg      { attack->service = SERVICES_OPENSMTPD; }
  | couriermsg        { attack->service = SERVICES_COURIER; }
  | openvpnmsg        { attack->service = SERVICES_OPENVPN; }
  | giteamsg          { attack->service = SERVICES_GITEA; }
  | openvpnpsmsg      { attack->service = SERVICES_OPENVPN_PS; }
  | sqlservrmsg       { attack->service = SERVICES_MSSQL; }
  | proxmoxvemsg      { attack->service = SERVICES_PROXMOXVE; }
  ;

/* an address */
addr:
    IPv4            {
                        attack->address.kind = ADDRKIND_IPv4;
                        strcpy(attack->address.value, $1);
                    }
  | IPv6            {
                        attack->address.kind = ADDRKIND_IPv6;
                        strcpy(attack->address.value, $1);
                    }
  | IPv6 '%' WORD   {   /* IPv6 address with interface name */
                        attack->address.kind = ADDRKIND_IPv6;
                        strcpy(attack->address.value, $1);
                    }
  | HOSTADDR        {
                        if (!attack_from_hostname(attack, $1)) {
                            YYABORT;
                        }
                    }
  ;

/* attack rules for SSHd */
sshmsg:
    /* login attempt from non-existent user, or from existent but non-allowed user */
    ssh_illegaluser
    /* incorrect login attempt from valid and allowed user */
  | ssh_authfail
  | ssh_noidentifstring
  | ssh_badprotocol
  | ssh_invalid_format
  | ssh_badkex
  ;

ssh_illegaluser:
    /* nonexistent user */
    SSH_INVALUSERPREF addr
  | SSH_INVALUSERPREF addr SSH_ADDR_SUFF
    /* existent, unallowed user */
  | SSH_NOTALLOWEDPREF addr SSH_NOTALLOWEDSUFF
  ;

ssh_authfail:
    SSH_LOGINERR_PREF addr SSH_ADDR_SUFF
  | SSH_LOGINERR_PAM addr
  | SSH_LOGINERR_PAM addr SSH_VIA
  | SSH_MAXAUTH addr SSH_ADDR_SUFF
  ;

ssh_noidentifstring:
    SSH_NOIDENTIFSTR addr
  | SSH_NOIDENTIFSTR addr SSH_ADDR_SUFF
  | SSH_DISCONNECT_PREF addr SSH_PREAUTH_SUFF
  | SSH_CONNECTION_CLOSED addr SSH_PREAUTH_SUFF { attack->dangerousness = 2; }
  ;

ssh_badprotocol:
    SSH_BADPROTOCOLIDENTIF addr SSH_BADPROTOCOLIDENTIF_SUFF
  ;

ssh_invalid_format:
    SSH_INVALIDFORMAT_PREF addr SSH_INVALIDFORMAT_SUFF
  ;

ssh_badkex:
    SSH_BADKEX_PREF addr SSH_BADKEX_SUFF
  ;

/* attacks and blocks from SSHGuard */
sshguardmsg:
    SSHGUARD_ATTACK_PREF addr SSHGUARD_ATTACK_SUFF
  | SSHGUARD_BLOCK_PREF addr SSHGUARD_BLOCK_SUFF
  ;

bindmsg:
    BIND_PREF addr BIND_QUERY_DENIED
  ;

/* attack rules for dovecot imap */
dovecotmsg:
    DOVECOT_IMAP_LOGINERR_PREF addr DOVECOT_IMAP_LOGINERR_SUFF
  ;

/* attack rules for UWIMAP */
uwimapmsg:
    UWIMAP_LOGINERR '[' addr ']'
  ;

cyrusimapmsg:
    CYRUSIMAP_SASL_LOGINERR_PREF addr CYRUSIMAP_SASL_LOGINERR_SUFF
  ;

/* cucipop reports @addr@ tried to log in with wrong password */
cucipopmsg:
    CUCIPOP_AUTHFAIL addr
  ;

/* */
eximmsg:
   EXIM_ESMTP_AUTHFAIL_PREF addr EXIM_ESMTP_AUTHFAIL_SUFF
 | EXIM_ESMTP_LOGINFAIL_PREF addr EXIM_ESMTP_LOGINFAIL_SUFF
 ;

sendmailmsg:
   SENDMAIL_RELAYDENIED_PREF addr SENDMAIL_RELAYDENIED_SUFF
 | SENDMAIL_AUTHFAILURE_PREF addr SENDMAIL_AUTHFAILURE_SUFF;
 ;

postfixmsg:
    POSTFIX_SASL_LOGINERR_PREF addr POSTFIX_SASL_LOGINERR_SUFF
  | POSTFIX_NO_AUTH_PREF addr ']'
  | POSTFIX_GREYLIST addr POSTFIX_GREYLIST_SUFF
  | POSTFIX_NONSMTP addr POSTFIX_NONSMTP_SUFF
  | POSTSCREEN_PREF addr POSTSCREEN_SUFF
  ;

/* attack rules for FreeBSD's ftpd */
freebsdftpdmsg:
    FREEBSDFTPD_LOGINERR_PREF addr FREEBSDFTPD_LOGINERR_SUFF
  ;

/* attack rules for ProFTPd */
proftpdmsg:
    PROFTPD_LOGINERR_PREF addr PROFTPD_LOGINERR_SUFF
  ;

/* attack rules for Pure-FTPd */
pureftpdmsg:
    PUREFTPD_LOGINERR_PREF addr PUREFTPD_LOGINERR_SUFF
  ;

/* attack rules for vsftpd */
vsftpdmsg:
    VSFTPD_LOGINERR_PREF addr VSFTPD_LOGINERR_SUFF
  ;

/* attack rules for cockpit */
cockpitmsg:
    COCKPIT_AUTHFAIL_PREF addr COCKPIT_AUTHFAIL_SUFF
  | COCKPIT_AUTHFAIL_PREF addr
  ;

/* attack rules for HTTP 401 Unauhtorized in common log format */
clfunauhtdmsg:
    addr CLF_UNAUTHOIRIZED_PREF CLF_UNAUTHOIRIZED_SUFF
  | addr CLF_REQUEST_PREF CLF_UNAUTHOIRIZED_SUFF
  ;

/* attack rules for probes for common web services */
clfwebprobesmsg:
    addr CLF_REQUEST_PREF CLFWEBPROBES_BOTSEARCH_SUFF
  ;

/* attack rules against common CMS frameworks */
clfcmsmsg:
    addr CLF_REQUEST_PREF CLF_LOGIN_URL_SUFF
  ;

/* opensmtpd */
opensmtpdmsg:
    OPENSMTPD_FAILED_CMD_PREF addr OPENSMTPD_AUTHFAIL_SUFF
  | OPENSMTPD_FAILED_CMD_PREF addr OPENSMTPD_UNSUPPORTED_CMD_SUFF
  ;

/* attack rules for courier imap/pop */
couriermsg:
    COURIER_AUTHFAIL_PREF '[' addr ']'
  ;

/* attack rules for openvpn */
openvpnmsg:
    addr OPENVPN_TLS_ERR_SUFF
  | '[' addr ']' OPENVPN_TLS_ERR_SUFF
  ;

/* attack rules for gitea */
giteamsg:
    GITEA_ERR_PREF addr
  | GITEA_ERR_PREF addr GITEA_ERR_SUFF
  | GITEA_ERR_PREF '[' addr ']'
  | GITEA_ERR_PREF '[' addr ']' GITEA_ERR_SUFF
  ;

/* attack rules for mssql */
sqlservrmsg:
    MSSQL_AUTHFAIL_PREF addr ']' 
  ;

/* attack rules for openvpn portshare */
openvpnpsmsg:
    OPENVPN_PS_TERM_PREF addr OPENVPN_PS_TERM_SUFF
  | OPENVPN_PS_TERM_PREF '[' addr ']' OPENVPN_PS_TERM_SUFF
  ;

 /* attack rules for Proxmox VE */
proxmoxvemsg:
    PROXMOXVE_AUTHFAIL_PREF addr PROXMOXVE_AUTHFAIL_SUFF
  ;

%%

static void yyerror(__attribute__((unused)) attack_t *a,
    __attribute__((unused)) const char *s) { /* do nothing */ }

int parse_line(char *str, attack_t *attack) {

    /* TODO: reduce danger for SERVICES_CLF_PROBES */
    attack->dangerousness = DEFAULT_ATTACKS_DANGEROUSNESS;

    scanner_init(str);
    int ret = yyparse(attack);
    scanner_fin();

    return ret;
}
