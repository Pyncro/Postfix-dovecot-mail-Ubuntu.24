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
