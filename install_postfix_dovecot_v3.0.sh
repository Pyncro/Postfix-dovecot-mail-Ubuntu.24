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

echo "✅ All done!"
echo -e "${RED}⚠️ Reminder: Review and modify OpenDKIM's main config files if needed (e.g., /etc/opendkim.conf). Follow part2-addition for slight changes.${NC}"

CONFIG_FILE="/etc/opendkim.conf"
TMP_FILE="/tmp/opendkim.conf.modified"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: $CONFIG_FILE not found."
  exit 1
fi

echo "📦 Backing up original config file to ${CONFIG_FILE}.bak"
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

echo "🛠 Modifying $CONFIG_FILE..."

# Build the modified config
{
  # Top section
  echo "#Add lines"
  echo "AutoRestart Yes"
  echo "AutoRestartRate 10/1h"
  echo ""

  # Original content
  cat "$CONFIG_FILE"

  # Bottom section
  echo ""
  echo "#Add lines at the end"
  echo "ExternalIgnoreList refile:/etc/opendkim/TrustedHosts"
  echo "InternalHosts refile:/etc/opendkim/TrustedHosts"
  echo "KeyTable refile:/etc/opendkim/KeyTable"
  echo "SigningTable refile:/etc/opendkim/SigningTable"
  echo "SignatureAlgorithm rsa-sha256"
} > "$TMP_FILE"

# Overwrite the original file
sudo mv "$TMP_FILE" "$CONFIG_FILE"

echo "✅ $CONFIG_FILE updated successfully."

# Prompt user to review/edit in nano
read -p "🔍 Press Enter to open the file in nano for review/editing..."
sudo nano "$CONFIG_FILE"

echo -e "${GREEN}TASK COMPLETE ✅${NC}"
