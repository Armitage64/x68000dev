#!/bin/bash
# Automated X68000 Test Script
# Runs MAME with Lua validation to verify program execution

set -e

cd "$(dirname "$0")/.."

BOOT_DISK="MasterDisk_V3.xdf"
LUA_SCRIPT="mame/test_simple_vram.lua"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

if [ ! -f "$LUA_SCRIPT" ]; then
    echo "Error: Lua test script not found: $LUA_SCRIPT"
    exit 1
fi

echo "========================================="
echo "X68000 Automated Test"
echo "========================================="
echo ""
echo "This will:"
echo "  1. Suppress the MAME warning screen via cfg pre-patch"
echo "  2. Boot X68000 in MAME"
echo "  3. Automatically wait 100 seconds for boot and execution"
echo "  4. Check VRAM for program activity"
echo "  5. Report test results"
echo ""
echo "Starting test..."
echo ""

# Pre-acknowledge the MAME warning before each launch. MAME resets 'warned' to the
# current timestamp at session exit, so we must patch it every run — not just the first.
# We set warned >> current_time so MAME sees no new warning to display on startup.
CFG_DIR="$HOME/.mame/cfg"
CFG_FILE="$CFG_DIR/x68000.cfg"
mkdir -p "$CFG_DIR"
if [ -f "$CFG_FILE" ]; then
    sed -i 's/warned="[0-9]*"/warned="9999999999"/' "$CFG_FILE"
else
    cat > "$CFG_FILE" <<'EOF'
<?xml version="1.0"?>
<mameconfig version="10">
    <system name="x68000">
        <ui_warnings launched="0" warned="9999999999">
            <feature device="x68000" type="graphics" status="imperfect" />
        </ui_warnings>
    </system>
</mameconfig>
EOF
fi

# Run MAME with Lua validation
mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -skip_gameinfo \
    -autoboot_script "$LUA_SCRIPT" 2>&1 | grep -E '\[LUA\]'

echo ""
echo "========================================="
echo "Test complete!"
echo "========================================="
