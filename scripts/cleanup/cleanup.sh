#!/bin/bash

# ============================================================================
# Cleanup Script for lf-backup-20251217
# ============================================================================
# This script removes unnecessary files and folders to reduce backup size.
# Estimated savings: ~1GB+ (excluding .git folders)
#
# NOTE: .git folders are NOT deleted (preserving Git history)
#
# Usage:
#   ./cleanup.sh          # Dry run - shows what would be deleted
#   ./cleanup.sh --execute # Actually delete the files
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if --execute flag is provided
DRY_RUN=true
if [[ "$1" == "--execute" ]]; then
    DRY_RUN=false
    echo -e "${RED}=== EXECUTE MODE: Files will be PERMANENTLY DELETED ===${NC}"
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Aborted."
        exit 0
    fi
else
    echo -e "${BLUE}=== DRY RUN MODE: No files will be deleted ===${NC}"
    echo -e "${YELLOW}Run with --execute to actually delete files${NC}"
    echo ""
fi

# Function to calculate size
calculate_size() {
    local path="$1"
    if [[ -e "$path" ]]; then
        du -sh "$path" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

echo "============================================================================"
echo "Starting cleanup process..."
echo "Base directory: $SCRIPT_DIR"
echo "============================================================================"
echo ""

# ============================================================================
# HIGH PRIORITY - Large folders (~1GB savings)
# ============================================================================

echo -e "${RED}=== HIGH PRIORITY (Large folders) ===${NC}"
echo ""

# 1. Python Virtual Environments (venv/) - ~906MB
echo -e "${BLUE}--- Python Virtual Environments (venv/) ---${NC}"
count=0
while IFS= read -r -d '' item; do
    if [[ -n "$item" ]]; then
        size=$(calculate_size "$item")
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $item (${size})"
        else
            echo -e "${RED}[DELETE]${NC} Removing: $item (${size})"
            rm -rf "$item"
        fi
        ((count++))
    fi
done < <(find "$SCRIPT_DIR" -type d -name "venv" -print0 2>/dev/null)
echo -e "${GREEN}Total: $count items${NC}"
echo ""

# 2. Go bin folder - ~44MB
echo -e "${BLUE}--- Go bin folder ---${NC}"
GO_BIN="$SCRIPT_DIR/legalforce/loc-app/schema/tools/go/bin"
if [[ -d "$GO_BIN" ]]; then
    size=$(calculate_size "$GO_BIN")
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $GO_BIN (${size})"
    else
        echo -e "${RED}[DELETE]${NC} Removing: $GO_BIN (${size})"
        rm -rf "$GO_BIN"
    fi
else
    echo -e "${GREEN}Not found${NC}"
fi
echo ""

# ============================================================================
# MEDIUM PRIORITY - Build artifacts and caches (~50MB savings)
# ============================================================================

echo -e "${YELLOW}=== MEDIUM PRIORITY (Build artifacts and caches) ===${NC}"
echo ""

# 3. Python __pycache__ folders - ~40MB
echo -e "${BLUE}--- Python cache folders (__pycache__/) ---${NC}"
count=0
while IFS= read -r -d '' item; do
    if [[ -n "$item" ]]; then
        size=$(calculate_size "$item")
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $item (${size})"
        else
            echo -e "${RED}[DELETE]${NC} Removing: $item (${size})"
            rm -rf "$item"
        fi
        ((count++))
    fi
done < <(find "$SCRIPT_DIR" -type d -name "__pycache__" -print0 2>/dev/null)
echo -e "${GREEN}Total: $count items${NC}"
echo ""

# 4. Nuxt.js build cache - ~3MB
echo -e "${BLUE}--- Nuxt.js build cache (.nuxt/) ---${NC}"
count=0
while IFS= read -r -d '' item; do
    if [[ -n "$item" ]]; then
        size=$(calculate_size "$item")
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $item (${size})"
        else
            echo -e "${RED}[DELETE]${NC} Removing: $item (${size})"
            rm -rf "$item"
        fi
        ((count++))
    fi
done < <(find "$SCRIPT_DIR" -type d \( -name ".nuxt" -o -name ".nuxt-jp" -o -name ".nuxt-us" \) -print0 2>/dev/null)
echo -e "${GREEN}Total: $count items${NC}"
echo ""

# 5. .NET obj folders (build intermediates) - ~3MB
echo -e "${BLUE}--- .NET obj folders ---${NC}"
count=0
while IFS= read -r -d '' item; do
    if [[ -n "$item" ]]; then
        size=$(calculate_size "$item")
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $item (${size})"
        else
            echo -e "${RED}[DELETE]${NC} Removing: $item (${size})"
            rm -rf "$item"
        fi
        ((count++))
    fi
done < <(find "$SCRIPT_DIR" -type d -name "obj" -path "*/rd-doc-write/*" -print0 2>/dev/null)
echo -e "${GREEN}Total: $count items${NC}"
echo ""

# 6. .NET bin/Debug folders
echo -e "${BLUE}--- .NET bin/Debug folders ---${NC}"
count=0
while IFS= read -r -d '' item; do
    if [[ -n "$item" ]]; then
        size=$(calculate_size "$item")
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $item (${size})"
        else
            echo -e "${RED}[DELETE]${NC} Removing: $item (${size})"
            rm -rf "$item"
        fi
        ((count++))
    fi
done < <(find "$SCRIPT_DIR" -type d -path "*/rd-doc-write/*/bin/Debug" -print0 2>/dev/null)
echo -e "${GREEN}Total: $count items${NC}"
echo ""

# ============================================================================
# LOW PRIORITY - Small files (minimal savings)
# ============================================================================

echo -e "${GREEN}=== LOW PRIORITY (Small files) ===${NC}"
echo ""

# 7. macOS .DS_Store files
echo -e "${BLUE}--- macOS .DS_Store files ---${NC}"
count=0
while IFS= read -r -d '' item; do
    if [[ -n "$item" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $item"
        else
            echo -e "${RED}[DELETE]${NC} Removing: $item"
            rm -f "$item"
        fi
        ((count++))
    fi
done < <(find "$SCRIPT_DIR" -type f -name ".DS_Store" -print0 2>/dev/null)
echo -e "${GREEN}Total: $count items${NC}"
echo ""

# 8. Log files in .vscode
echo -e "${BLUE}--- VSCode log files ---${NC}"
count=0
while IFS= read -r -d '' item; do
    if [[ -n "$item" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $item"
        else
            echo -e "${RED}[DELETE]${NC} Removing: $item"
            rm -f "$item"
        fi
        ((count++))
    fi
done < <(find "$SCRIPT_DIR" -type f -name "*.log" -path "*/.vscode/*" -print0 2>/dev/null)
echo -e "${GREEN}Total: $count items${NC}"
echo ""

# 9. Python .pyc files (standalone)
echo -e "${BLUE}--- Python compiled files (*.pyc) ---${NC}"
count=0
while IFS= read -r -d '' item; do
    if [[ -n "$item" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete: $item"
        else
            echo -e "${RED}[DELETE]${NC} Removing: $item"
            rm -f "$item"
        fi
        ((count++))
    fi
done < <(find "$SCRIPT_DIR" -type f -name "*.pyc" -print0 2>/dev/null)
echo -e "${GREEN}Total: $count items${NC}"
echo ""

# ============================================================================
# Summary
# ============================================================================

echo "============================================================================"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}DRY RUN COMPLETE${NC}"
    echo ""
    echo "To actually delete these files, run:"
    echo -e "${YELLOW}  ./cleanup.sh --execute${NC}"
else
    echo -e "${GREEN}CLEANUP COMPLETE${NC}"
    echo ""
    echo "Calculating new size..."
    NEW_SIZE=$(du -sh "$SCRIPT_DIR" 2>/dev/null | cut -f1)
    echo -e "New total size: ${GREEN}${NEW_SIZE}${NC}"
fi
echo "============================================================================"
