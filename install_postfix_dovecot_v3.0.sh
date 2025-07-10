#!/bin/bash

# Color setup
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DOMAIN="example.com"
SELECTOR="mail"
DKIM_DIR="/etc/opendkim"

echo -e "${YELLOW}Installing OpenDKIM and tools...${NC}"
sudo apt-get update
sudo apt-get install -y opendkim opendkim-tools

echo -e "${GREEN}Starting and enabling OpenDKIM service...${NC}"
sudo systemctl start opendkim
sudo systemctl enable opendkim

echo -e "${YELLOW}Generating DKIM keys...${NC}"
sudo mkdir -p $DKIM_DIR
sudo opendkim-genkey -D $DKIM_DIR --domain=$DOMAIN --selector=$SELECTOR

echo -e "${GREEN}Generated DKIM key:${NC}"
cat $DKIM_DIR/${SELECTOR}.txt

echo -e "${YELLOW}⚠️ Please copy the above DKIM TXT record to your DNS provider."
read -p "Press Enter to continue after you've done that..."

echo -e "${GREEN}Setting ownership of DKIM directory...${NC}"
sudo chown -R opendkim:opendkim $DKIM_DIR

# Automatically create TrustedHosts
echo -e "${GREEN}Creating TrustedHosts file...${NC}"
cat <<EOF | sudo tee /etc/opendkim/TrustedHosts > /dev/null
127.0.0.1
localhost
$DOMAIN
EOF

# Automatically create KeyTable
echo -e "${GREEN}Creating KeyTable file...${NC}"
cat <<EOF | sudo tee /etc/opendkim/KeyTable > /dev/null
$SELECTOR._domainkey.$DOMAIN $DOMAIN:$SELECTOR:$DKIM_DIR/${SELECTOR}.private
EOF

# Automatically create SigningTable
echo -e "${GREEN}Creating SigningTable file...${NC}"
cat <<EOF | sudo tee /etc/opendkim/SigningTable > /dev/null
*@${DOMAIN} $SELECTOR._domainkey.${DOMAIN}
EOF

echo -e "${GREEN}Restarting OpenDKIM and Postfix...${NC}"
sudo systemctl restart opendkim
sudo systemctl restart postfix

echo -e "${GREEN}TASK COMPLETE ✅${NC}"
echo -e "${RED}⚠️ Reminder: Review and modify OpenDKIM's main config files if needed (e.g., /etc/opendkim.conf). Follow part2-modifications.${NC}"
