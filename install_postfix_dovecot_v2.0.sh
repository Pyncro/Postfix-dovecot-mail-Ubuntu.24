#!/bin/bash

# Color setup
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

set -e

echo -e "${GREEN}✅ Starting Mail Server Installation...${NC}"

# Step 1: Update system
echo -e "${YELLOW}Updating system packages...${NC}"
apt-get update && apt-get upgrade -y
echo -e "${GREEN}✔️ System updated successfully.${NC}"

# Step 2: Set hostname
echo -e "${YELLOW}Setting hostname to mail.example.com...${NC}"
hostnamectl set-hostname mail.example.com
echo -e "${GREEN}✔️ Hostname set.${NC}"

# Step 3: Installing Postfix
MAILNAME="example.com"
echo -e "${YELLOW}Installing Postfix...${NC}"

# Preconfigure Postfix
echo -e "${YELLOW}Pre-configuring Postfix...${NC}"
echo "postfix postfix/mailname string $MAILNAME" | sudo debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | sudo debconf-set-selections

# Install Postfix
echo -e "${YELLOW}Installing Postfix package...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
echo -e "${GREEN}✔️ Postfix installed.${NC}"

# Set mailname
echo "$MAILNAME" | sudo tee /etc/mailname > /dev/null

# Configure main.cf settings
echo -e "${YELLOW}Configuring Postfix settings...${NC}"
sudo postconf -e "myhostname = $MAILNAME"
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
sudo postconf -e "home_mailbox = Maildir/"
sudo postconf -e "smtpd_sasl_type = dovecot"
sudo postconf -e "smtpd_sasl_path = private/auth"
sudo postconf -e "smtpd_sasl_auth_enable = yes"

# Install mailutils
echo -e "${YELLOW}Installing mailutils...${NC}"
apt install -y postfix mailutils

# Restart Postfix
echo -e "${YELLOW}Restarting Postfix...${NC}"
sudo systemctl enable postfix
sudo systemctl restart postfix
echo -e "${GREEN}✔️ Postfix is active and running.${NC}"
sudo systemctl status postfix --no-pager

# Step 4: Installing Dovecot
echo -e "${YELLOW}Installing Dovecot...${NC}"
sudo apt update
sudo apt install -y dovecot-imapd dovecot-pop3d dovecot-lmtpd
echo -e "${GREEN}✔️ Dovecot installed.${NC}"

# Configure dovecot.conf
echo -e "${YELLOW}Configuring dovecot.conf...${NC}"
DOVECOT_CONF="/etc/dovecot/dovecot.conf"
BACKUP_FILE="${DOVECOT_CONF}.bak.$(date +%F_%T)"
LINE_TO_ADD="protocols = pop3 pop3s imap imaps"

if [[ ! -f "$DOVECOT_CONF" ]]; then
  echo -e "${RED}❌ Error: $DOVECOT_CONF not found.${NC}"
  exit 1
fi

cp "$DOVECOT_CONF" "$BACKUP_FILE"
echo -e "${GREEN}✔️ Backup created at $BACKUP_FILE${NC}"

if grep -Fxq "$LINE_TO_ADD" "$DOVECOT_CONF"; then
  echo -e "${YELLOW}Line already present in dovecot.conf, skipping...${NC}"
else
  echo "$LINE_TO_ADD" >> "$DOVECOT_CONF"
  echo -e "${GREEN}✔️ Line added to dovecot.conf${NC}"
fi

# Modify 10-auth.conf
echo -e "${YELLOW}Modifying 10-auth.conf...${NC}"
AUTH_CONF="/etc/dovecot/conf.d/10-auth.conf"

if grep -q '^auth_mechanisms = plain$' "$AUTH_CONF"; then
  sudo sed -i 's/^auth_mechanisms = plain$/auth_mechanisms = plain login/' "$AUTH_CONF"
  echo -e "${GREEN}✔️ auth_mechanisms updated with 'login'.${NC}"
fi

if ! grep -q '^mail_location = maildir:~/Maildir' "$AUTH_CONF"; then
  echo 'mail_location = maildir:~/Maildir' | sudo tee -a "$AUTH_CONF" > /dev/null
  echo -e "${GREEN}✔️ Added mail_location to 10-auth.conf.${NC}"
fi

# Step 5: SSL Certificate with Certbot
echo -e "${YELLOW}Installing Certbot and requesting SSL certificate...${NC}"
sudo apt update
sudo apt install -y certbot

sudo certbot certonly --standalone \
  --non-interactive \
  --agree-tos \
  --email info@example.com \
  -d mail.example.com
echo -e "${GREEN}✔️ SSL certificate obtained using Certbot.${NC}"

# Final warning
echo -e "${RED}⚠️ WARNING: Please manually review 10-auth.conf and add brackets if needed."
echo -e "Refer to AI or your GitHub documentation for correct formatting.${NC}"

echo -e "${GREEN}✅ First part of setup completed successfully.${NC}"
echo -e "${YELLOW}⚠️ Before continuing, make sure your VPS DNS and mail domain are properly configured.${NC}"


