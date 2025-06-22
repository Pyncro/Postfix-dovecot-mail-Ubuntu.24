# Postfix-dovecot-mail-Ubuntu.24
Postfix Mail Server with Dovecot on Linux Ubuntu



https://hetmanrecovery.com/recovery_news/how-to-install-and-configure-postfix-mail-server-with-dovecot-on-linux-ubuntu.htm
https://www.youtube.com/watch?v=P5NeyiRPYiY&list=LL&index=1&t=7s
https://chatgpt.com/




sudo -s

apt-get update
apt-get upgrade

sudo hostnamectl set-hostname mail.example.com

sudo apt install postfix #pick internet site

sudo nano /etc/postfix/main.cf

myhostname = mail.example.com
mydomain = example.com
myorigin = /etc/mailname
inet_interfaces = all
mydestination = $myhostname, $mydomain, localhost.localdomain, localhost


sudo systemctl enable postfix
sudo systemctl start postfix
sudo systemctl restart postfix

sudo apt install dovecot-imapd dovecot-pop3d

sudo nano /etc/dovecot/dovecot.conf

protocols = imap pop3 lmtp
mail_location = maildir:~/Maildir

sudo systemctl enable dovecot
sudo systemctl start dovecot
sudo systemctl restart dovecot

adduser info #fill everything blank 
usermod -aG sudo info

sudo hostnamectl set-hostname example.com

sudo apt-get install postfix #Internet site , example.com

sudo systemctl enable postfix
sudo systemctl start postfix
sudo systemctl restart postfix

apt install mailutils

Sudo nano /etc/postfix/main.cf #Add the line home_mailbox= Maildir/:

sudo apt-get install dovecot-imapd dovecot-pop3d

sudo systemctl enable dovecot
sudo systemctl start dovecot
sudo systemctl restart dovecot

nano /etc/dovecot/dovecot.conf
protocols = pop3 pop3s imap imaps

apt-get install opendkim opendkim-tools
sudo systemctl enable opendkim
sudo systemctl start opendkim

mkdir /etc/opendkim
opendkim-genkey -D /etc/opendkim/ --domain example.com --selector mail 

cat /etc/opendkim/mail.txt

#ASK USER TO COPY PASTE THE KEY INTO THEIR CONTROL PANEL
#THEY MUST PRESS ENTER TO CONTINUE THE BASH SCRIPT

sudo chown -R opendkim:opendkim /etc/opendkim
sudo nano /etc/opendkim.conf

#Here, you need to comment and add a few lines
AutoRestart Yes
AutoRestartRate 10/1h
Umask 002
Syslog yes
SyslogSuccess Yes
LogWhy Yes
Mode sv
Canonicalization relaxed/simple
UserID opendkim:opendkim
Socket inet:8891@localhost
PidFile /var/run/opendkim/opendkim.pid
ExternalIgnoreList refile:/etc/opendkim/TrustedHosts
InternalHosts refile:/etc/opendkim/TrustedHosts
KeyTable refile:/etc/opendkim/KeyTable
SigningTable refile:/etc/opendkim/SigningTable
SignatureAlgorithm rsa-sha256

sudo nano /etc/opendkim/TrustedHosts #add domain name example.com

sudo nano /etc/opendkim/KeyTable
mail._domainkey.example.com example.com:mail:/etc/opendkim/dkim.private

sudo nano /etc/opendkim/SigningTable
*@hetmansoftware.com mail._domainkey.hetmansoftware.com

sudo systemctl restart opendkim
sudo systemctl restart postfix


sudo nano /etc/postfix/master.cf
#Find the submission section. It’s usually commented out by default. You want it to look like this:
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING

nano /etc/postfix/main.cf
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes

nano /etc/dovecot/conf.d/10-master.conf
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}

sudo systemctl restart postfix
sudo systemctl restart dovecot

ufw allow 587
ufw allow 22
ufw allow 25
ufw allow 993
ufw allow 995
ufw allow 80
ufw allow 443

sudo systemctl restart dovecot
ls -l /var/spool/postfix/private/auth

sudo systemctl restart postfix
sudo nano /etc/dovecot/conf.d/10-auth.conf
auth_mechanisms = plain login


sudo nano /etc/dovecot/conf.d/10-auth.conf
auth_username_format = %n
sudo systemctl restart dovecot

sudo apt update
sudo apt install certbot
sudo certbot certonly --standalone -d mail.example.com

nano /etc/postfix/main.cf
smtpd_tls_cert_file=/etc/letsencrypt/live/mail.example.com/fullchain.pem
smtpd_tls_key_file=/etc/letsencrypt/live/mail.example.com/privkey.pem
smtpd_use_tls=yes
smtpd_tls_security_level=may
smtpd_tls_auth_only = yes

nano /etc/dovecot/conf.d/10-ssl.conf

ssl = required
ssl_cert = </etc/letsencrypt/live/mail.example.com/fullchain.pem
ssl_key = </etc/letsencrypt/live/mail.example.com/privkey.pem
ssl_protocols = !SSLv3 !TLSv1 !TLSv1.1 TLSv1.2 TLSv1.3

sudo systemctl restart dovecot
sudo systemctl restart postfix
