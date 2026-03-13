#!/bin/bash

BACKUP_FILE="/etc/apt/sources.list.backup_$(date +%Y%m%d_%H%M%S)"

echo "========== Backup current APT sources =========="
echo ""

echo "Current APT sources:"
cat /etc/apt/sources.list

echo ""
echo "Backing up to $BACKUP_FILE..."
sudo cp /etc/apt/sources.list "$BACKUP_FILE"

echo ""
echo "Backup complete!"
echo "To restore, run:"
echo "  sudo cp $BACKUP_FILE /etc/apt/sources.list"
echo "  sudo apt update"
