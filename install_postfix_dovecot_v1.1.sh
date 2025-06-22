#!/bin/bash

# STEP 1: Gain root access
sudo -s

# STEP 2: System update
apt-get update
apt-get upgrade -y

# STEP 3: Set hostname
sudo hostnamectl set-hostname mail.example.com

# STEP 4: Install and configure Postfix
sudo apt install postfix -y
# During setup, select 'Internet Site' and set system mail name to example.com

sudo systemctl enable postfix
sudo systemctl start postfix
sudo systemctl restart postfix

# STEP 5: Install and configure Dovecot
sudo apt install dovecot-lmtpd -y
sudo apt install dovecot-imapd dovecot-pop3d -y

sudo bash -c 'cat > /etc/dovecot/dovecot.conf <<EOF
protocols = imap pop3 lmtp
mail_location = maildir:~/Maildir
EOF'

sudo systemctl enable dovecot
sudo systemctl start dovecot
sudo systemctl restart dovecot

# ... (rest of script remains unchanged)
echo "✅ TASK COMPLETED"
