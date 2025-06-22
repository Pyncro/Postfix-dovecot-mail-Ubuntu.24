#!/bin/bash

set -e

echo "✅ Starting Mail Server Installation..."

# Step 1: Update system
echo "✅ Updating system..."
apt-get update && apt-get upgrade -y

# Step 2: Set hostname
echo "✅ Setting hostname..."
hostnamectl set-hostname mail.example.com

# Step 3: Install Postfix
echo "✅ Installing Postfix..."
debconf-set-selections <<< "postfix postfix/mailname string example.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt install -y postfix mailutils

# Step 4: Configure main.cf
echo "✅ Configuring Postfix..."
postconf -e "myhostname = mail.example.com"
postconf -e "mydomain = example.com"
postconf -e "myorigin = /etc/mailname"
postconf -e "inet_interfaces = all"
postconf -e "mydestination = $myhostname, $mydomain, localhost.localdomain, localhost"
postconf -e "home_mailbox = Maildir/"

systemctl enable postfix
systemctl restart postfix

# Step 5: Install Dovecot
echo "✅ Installing Dovecot..."
apt install -y dovecot-imapd dovecot-pop3d dovecot-lmtpd

# Step 6: Configure Dovecot
echo "✅ Configuring Dovecot..."
cat > /etc/dovecot/dovecot.conf <<EOF
protocols = imap pop3 lmtp
mail_location = maildir:~/Maildir
EOF

sed -i 's/^#\?protocols =.*/protocols = imap pop3 lmtp/' /etc/dovecot/dovecot.conf
echo "auth_mechanisms = plain login" >> /etc/dovecot/conf.d/10-auth.conf
echo "auth_username_format = %n" >> /etc/dovecot/conf.d/10-auth.conf

cat >> /etc/dovecot/conf.d/10-master.conf <<EOF
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
EOF

cat >> /etc/dovecot/conf.d/10-mail.conf <<EOF
mail_location = maildir:~/Maildir
EOF

systemctl enable dovecot
systemctl restart dovecot

# Step 7: Create user
echo "✅ Creating mail user..."
adduser --gecos "" info
usermod -aG sudo info

# Step 8: Install and configure OpenDKIM
echo "✅ Installing OpenDKIM..."
apt-get install -y opendkim opendkim-tools
mkdir -p /etc/opendkim
opendkim-genkey -D /etc/opendkim/ --domain example.com --selector mail

echo "✅ Generated DKIM Key:"
cat /etc/opendkim/mail.txt

read -p "⏸️  Please copy the above DKIM TXT record to your domain DNS and press Enter to continue..."

chown -R opendkim:opendkim /etc/opendkim

# Configure OpenDKIM
cat > /etc/opendkim.conf <<EOF
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
EOF

echo "example.com" > /etc/opendkim/TrustedHosts
echo "mail._domainkey.example.com example.com:mail:/etc/opendkim/mail.private" > /etc/opendkim/KeyTable
echo "*@example.com mail._domainkey.example.com" > /etc/opendkim/SigningTable

systemctl enable opendkim
systemctl restart opendkim
systemctl restart postfix

# Step 9: Postfix submission config
echo "✅ Enabling submission port..."
sed -i '/^#submission inet n/,/^ *-o milter_macro_daemon_name=ORIGINATING/ s/^#//' /etc/postfix/master.cf

postconf -e "smtpd_sasl_type = dovecot"
postconf -e "smtpd_sasl_path = private/auth"
postconf -e "smtpd_sasl_auth_enable = yes"

systemctl restart postfix
systemctl restart dovecot

# Step 10: Firewall
echo "✅ Configuring firewall..."
ufw allow 22
ufw allow 25,80,443,587,993/tcp

# Step 11: SSL with Certbot
echo "✅ Installing SSL Cert with Certbot..."
apt install -y certbot
certbot certonly --standalone -d mail.example.com

postconf -e "smtpd_tls_cert_file=/etc/letsencrypt/live/mail.example.com/fullchain.pem"
postconf -e "smtpd_tls_key_file=/etc/letsencrypt/live/mail.example.com/privkey.pem"
postconf -e "smtpd_use_tls=yes"
postconf -e "smtpd_tls_security_level=may"
postconf -e "smtpd_tls_auth_only = yes"

cat >> /etc/dovecot/conf.d/10-ssl.conf <<EOF
ssl = required
ssl_cert = </etc/letsencrypt/live/mail.example.com/fullchain.pem
ssl_key = </etc/letsencrypt/live/mail.example.com/privkey.pem
ssl_protocols = !SSLv3 !TLSv1 !TLSv1.1 TLSv1.2 TLSv1.3
EOF

systemctl restart dovecot
systemctl restart postfix

# Final Check
#!/bin/bash

echo "🔧 Fixing Dovecot: Adding missing passdb and userdb..."

# Backup the existing config
cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.bak

# Apply the proper configuration
cat <<EOF > /etc/dovecot/conf.d/10-auth.conf
disable_plaintext_auth = no
auth_mechanisms = plain login

passdb {
  driver = pam
}

userdb {
  driver = passwd
}
EOF

echo "✅ Configuration updated."

# Restart dovecot
echo "🔄 Restarting Dovecot..."
systemctl restart dovecot

# Check if socket was created
echo "📂 Checking for Postfix auth socket:"
ls -l /var/spool/postfix/private/auth || echo "❌ Socket not found. Check Dovecot logs."

echo -e "\n✅✅✅ TASK COMPLETED — Postfix + Dovecot + DKIM + TLS mail server is now installed! ✅✅✅"
