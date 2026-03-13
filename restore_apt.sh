#!/bin/bash

echo "========== Restore APT sources =========="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_FILE=$(ls -t /etc/apt/sources.list.backup_* 2>/dev/null | head -1)

if [ -z "$BACKUP_FILE" ]; then
    echo "No backup file found!"
    exit 1
fi

echo "Found backup: $BACKUP_FILE"
echo "Restoring..."
sudo cp "$BACKUP_FILE" /etc/apt/sources.list

echo ""
echo "Updating APT..."
sudo apt update

echo ""
echo "========== Restore complete =========="
