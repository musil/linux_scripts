#!/bin/bash

# Script to display last backup information with formatted output
# Enhanced version of vypis-last-backup.sh

BACKUP_DIR="/mnt/zalohy"
CURRENT_DATE=$(date +%Y%m%d)

echo "===== BACKUP STATUS REPORT ====="
echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S')"
echo "===============================\n"

echo "| SYSTEM             | BACKUP DATE | BACKUP TIME | AGE       | STATUS  |"
echo "|--------------------+-------------+-------------+-----------+---------|"

# Check each backup directory
find "$BACKUP_DIR" -maxdepth 2 -name ".last-backup.txt" -type f | sort | while read backup_file; do
    # Extract system name from path
    system_dir=$(dirname "$backup_file")
    system_name=$(basename "$system_dir")
    
    # Read backup timestamp
    backup_info=$(cat "$backup_file")
    
    # Parse date and time from backup info
    if [[ $backup_info =~ ([0-9]{8})-([0-9]{6}) ]]; then
        # Use regex capture groups if standard format found
        backup_date="${BASH_REMATCH[1]}"
        backup_time="${BASH_REMATCH[1]:0:4}-${BASH_REMATCH[1]:4:2}-${BASH_REMATCH[1]:6:2}"
        backup_clock="${BASH_REMATCH[2]:0:2}:${BASH_REMATCH[2]:2:2}:${BASH_REMATCH[2]:4:2}"
    else
        # Fallback if format is different
        backup_date=$(echo "$backup_info" | grep -oE '[0-9]{8}' || echo "Unknown")
        backup_time="Unknown"
        backup_clock="Unknown"
    fi
    
    # Calculate age in days
    if [[ $backup_date =~ ^[0-9]{8}$ ]]; then
        age_days=$(( ($(date +%s) - $(date -d "${backup_date:0:4}-${backup_date:4:2}-${backup_date:6:2}" +%s)) / 86400 ))
        
        # Determine status based on age
        if [ "$age_days" -eq 0 ]; then
            status="✅ OK"
        elif [ "$age_days" -eq 1 ]; then
            status="⚠️ 1 day"
        elif [ "$age_days" -le 3 ]; then
            status="⚠️ $age_days days"
        else
            status="❌ $age_days days"
        fi
    else
        age_days="Unknown"
        status="❓ Unknown"
    fi
    
    # Format output as table row
    printf "| %-18s | %-11s | %-11s | %-9s | %-7s |\n" \
        "$system_name" \
        "$backup_time" \
        "$backup_clock" \
        "$age_days days" \
        "$status"
done

echo "===============================\n"

# Check for missing backups
echo "Missing backup files:"
for dir in "$BACKUP_DIR"/*; do
    if [ -d "$dir" ] && [ ! -f "$dir/.last-backup.txt" ]; then
        echo "⚠️ $(basename "$dir") - No backup file found"
    fi
done

