#!/bin/bash

set -e

echo "✅ Starting Mail Server Installation..."

# Step 1: Update system
echo "✅ Updating system..."
apt-get update && apt-get upgrade -y

# Step 2: Set hostname
echo "✅ Setting hostname..."
hostnamectl set-hostname mail.example.com

# Step 3: Installing Postfix
#!/bin/bash

set -e

MAILNAME="example.com"

# Preconfigure Postfix with minimal changes
echo "postfix postfix/mailname string $MAILNAME" | sudo debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | sudo debconf-set-selections

# Install postfix without interactive prompts
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postfix

# Ensure mailname is set correctly
echo "$MAILNAME" | sudo tee /etc/mailname > /dev/null

# Safely update only the desired settings in main.cf
sudo postconf -e "myhostname = $MAILNAME"
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
sudo postconf -e "home_mailbox = Maildir/"

# Mailutils install
apt install -y postfix mailutils

# Optional: restart Postfix to apply changes
sudo systemctl enable postfix
sudo systemctl restart postfix

# Show status
sudo systemctl status postfix --no-pager


# DOVECOT TIME
echo "✅ Installing Dovecot..."

set -e

sudo apt update
sudo apt install -y dovecot-imapd dovecot-pop3d dovecot-lmtpd

echo "✅ DOVECOT.CONF INITIATION"
# Path to dovecot.conf
DOVECOT_CONF="/etc/dovecot/dovecot.conf"

# Backup file with timestamp
BACKUP_FILE="${DOVECOT_CONF}.bak.$(date +%F_%T)"

# Line to add
LINE_TO_ADD="protocols = pop3 pop3s imap imaps"

# Check if dovecot.conf exists
if [[ ! -f "$DOVECOT_CONF" ]]; then
  echo "Error: $DOVECOT_CONF not found."
  exit 1
fi

# Make a backup
cp "$DOVECOT_CONF" "$BACKUP_FILE"
echo "Backup created at $BACKUP_FILE"

# Check if the line already exists (exact match)
if grep -Fxq "$LINE_TO_ADD" "$DOVECOT_CONF"; then
  echo "Line already present in $DOVECOT_CONF, no changes made."
else
  echo "$LINE_TO_ADD" >> "$DOVECOT_CONF"
  echo "Line added to $DOVECOT_CONF"
fi
echo "✅ DOVECOT.CONF DONE"
# --------- 1. Modify 10-auth.conf ---------
AUTH_CONF="/etc/dovecot/conf.d/10-auth.conf"

# Append ' login' to the existing auth_mechanisms line if not already there
if grep -q '^auth_mechanisms = plain$' "$AUTH_CONF"; then
    sudo sed -i 's/^auth_mechanisms = plain$/auth_mechanisms = plain login/' "$AUTH_CONF"
fi

# Add 'auth_username_format = %n' only if it's not already set
if ! grep -q '^auth_username_format = %n' "$AUTH_CONF"; then
    echo 'auth_username_format = %n' | sudo tee -a "$AUTH_CONF" > /dev/null
fi

echo "⚠️⚠️⚠️⚠️⚠️WARNING , PLEASE MODIFY 10-AUT.CONF WITH BRACKETS , REFER TO AI OR MY GITHUB FOR MORE INFORMATION⚠️⚠️⚠️⚠️⚠️"

echo "first part completed , before heading over to the second part please ensure that you've configured most of your VPS linking"


