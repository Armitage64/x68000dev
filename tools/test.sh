#!/bin/bash
# X68000 Test Harness
# Boots the X68000 in MAME with the development disk

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

BOOT_DISK="MasterDisk_V3.xdf"
PROGRAM="build/bin/program.x"
HELLOC="build/bin/helloc.x"

if [ ! -f "$BOOT_DISK" ]; then
    echo "Error: Boot disk not found: $BOOT_DISK"
    exit 1
fi

if [ ! -f "$PROGRAM" ]; then
    echo "Warning: $PROGRAM not found — run 'make all' first"
fi
if [ ! -f "$HELLOC" ]; then
    echo "Warning: $HELLOC not found — run 'make all' first"
fi

# Install both programs to the boot disk so they are available at the A> prompt
if [ -f "$PROGRAM" ]; then
    mcopy -i "$BOOT_DISK" -o "$PROGRAM" ::PROGRAM.X
fi
if [ -f "$HELLOC" ]; then
    mcopy -i "$BOOT_DISK" -o "$HELLOC" ::HELLOC.X
fi

echo "Booting X68000 with disk: $BOOT_DISK"
echo "Programs installed: PROGRAM.X, HELLOC.X"
echo "At the A> prompt, run: A:PROGRAM.X  or  A:HELLOC.X"
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

# Launch MAME in the background
mame x68000 \
    -flop1 "$BOOT_DISK" \
    -window \
    -skip_gameinfo \
    -nomouse &
MAME_PID=$!

# Wait for MAME window to appear. The cfg patch above suppresses the warning screen,
# but we still do a XTEST click (no --window = XTEST, not XSendEvent) as a fallback
# in case the cfg patch did not take effect for any reason.
for i in $(seq 1 30); do
    sleep 0.5
    WID=$(xdotool search --pid "$MAME_PID" 2>/dev/null | tail -1)
    if [ -n "$WID" ]; then
        echo "Found MAME window, dismissing warning..."
        sleep 3.0
        eval "$(xdotool getwindowgeometry --shell "$WID" 2>/dev/null)" || true
        CX=$(( X + WIDTH  / 2 ))
        CY=$(( Y + HEIGHT / 2 ))
        xdotool mousemove "$CX" "$CY" 2>/dev/null || true
        sleep 0.1
        xdotool click 1 2>/dev/null || true
        break
    fi
done

wait "$MAME_PID"
echo ""
echo "Done."
