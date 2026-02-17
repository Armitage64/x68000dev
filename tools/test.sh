#!/bin/bash
# X68000 Test Harness
# Boots the X68000 in MAME with the development disk

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOT_DISK="$SCRIPT_DIR/../MasterDisk_V3.xdf"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

# MAME shows an imperfect-emulation warning when launched > warned in cfg.
# Pre-set warned to a large value so the warning is always suppressed.
mkdir -p ~/.mame/cfg
cat > ~/.mame/cfg/x68000.cfg << 'EOF'
<?xml version="1.0"?>
<mameconfig version="10">
    <system name="x68000">
        <ui_warnings launched="0" warned="9999999999">
            <feature device="x68000" type="graphics" status="imperfect" />
        </ui_warnings>
        <input>
            <keyboard tag=":keyboard:x68k" enabled="1" />
        </input>
    </system>
</mameconfig>
EOF

echo "Booting X68000 with disk: $BOOT_DISK"
echo ""

mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -skip_gameinfo
