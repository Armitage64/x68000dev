-- MAME X68000 Auto-boot and Test Script
-- Automatically executes program from floppy disk
--
-- This script automates the boot process and runs the program
-- Note: Full keyboard automation requires more complex MAME Lua API usage
-- This is a simplified version for demonstration

local function main()
    -- Get machine and screen
    local machine = manager.machine
    local screen = machine.screens[":screen"]

    print("MAME X68000 Automation Started")

    -- Wait for boot to complete (Human68k prompt)
    -- X68000 takes about 8 seconds to boot to prompt
    print("Waiting for Human68k boot...")
    emu.wait(8.0)

    -- Note: Full keyboard automation would go here
    -- The current MAME Lua API for keyboard input is complex
    -- and varies by version. For now, manual input is required
    -- or use -autoboot_command if available in your MAME version

    print("Boot complete. Please type: A:HELLOA.X")
    print("(Automated keyboard input requires MAME version-specific API)")

    -- Let program run for a while
    emu.wait(10.0)

    -- Take screenshot if possible
    if screen then
        screen:snapshot("screenshot.png")
        print("Screenshot saved: screenshot.png")
    end

    -- Keep running
    emu.wait(5.0)

    print("Test complete!")
end

function typeKeys(text)
    -- This is a placeholder - actual implementation requires
    -- MAME-version-specific keyboard input handling
    for i = 1, #text do
        local char = text:sub(i,i)
        emu.wait(0.1)
    end
end

function pressKey(keyname)
    -- Placeholder for key press simulation
    emu.wait(0.1)
end

-- Start automation when MAME starts
emu.register_start(main)
