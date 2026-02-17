-- Monitor boot process over time
print("[BOOT] === Boot Process Monitor ===")

local function check_boot_progress()
    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then return nil end

    local mem = cpu.spaces["program"]
    if not mem then return nil end

    -- Check various indicators of boot progress
    local indicators = {
        text_vram = 0,
        gvram = 0,
        ram_0x6800 = 0,
        ram_0x10000 = 0
    }

    -- Sample Text VRAM for boot messages
    for i = 0, 100, 10 do
        local ok, val = pcall(function() return mem:read_u8(0xE00000 + i) end)
        if ok and val ~= 0 and val ~= 0xFF then
            indicators.text_vram = indicators.text_vram + 1
        end
    end

    -- Sample GVRAM
    for i = 0, 100, 10 do
        local ok, val = pcall(function() return mem:read_u16(0xC00000 + i) end)
        if ok and val ~= 0 then
            indicators.gvram = indicators.gvram + 1
        end
    end

    -- Check program load area
    for i = 0, 100, 10 do
        local ok, val = pcall(function() return mem:read_u8(0x6800 + i) end)
        if ok and val ~= 0 and val ~= 0xFF then
            indicators.ram_0x6800 = indicators.ram_0x6800 + 1
        end
    end

    -- Check general RAM
    for i = 0, 100, 10 do
        local ok, val = pcall(function() return mem:read_u8(0x10000 + i) end)
        if ok and val ~= 0 and val ~= 0xFF then
            indicators.ram_0x10000 = indicators.ram_0x10000 + 1
        end
    end

    return indicators
end

local function monitor_boot()
    print("[BOOT] Monitoring boot process...")
    print("[BOOT] Time(s) | TextVRAM | GVRAM | RAM@6800 | RAM@10000")
    print("[BOOT] " .. string.rep("-", 60))

    for t = 0, 20, 2 do
        emu.wait(2.0)

        local ind = check_boot_progress()
        if ind then
            print(string.format("[BOOT] %6.1f | %8d | %5d | %8d | %9d",
                emu.time(), ind.text_vram, ind.gvram, ind.ram_0x6800, ind.ram_0x10000))
        else
            print(string.format("[BOOT] %6.1f | ERROR accessing memory", emu.time()))
        end
    end

    print("[BOOT] " .. string.rep("-", 60))
    print("[BOOT] Monitoring complete")

    -- Final check
    local final = check_boot_progress()
    if final then
        local total_activity = final.text_vram + final.gvram + final.ram_0x6800 + final.ram_0x10000

        if total_activity > 0 then
            print(string.format("[BOOT] ✓ ACTIVITY DETECTED (total: %d indicators)", total_activity))
            if final.text_vram > 0 then
                print("[BOOT]   - Text VRAM has content (boot messages?)")
            end
            if final.gvram > 0 then
                print("[BOOT]   - GVRAM has content (graphics?)")
            end
            if final.ram_0x6800 > 0 then
                print("[BOOT]   - Program area has content (code loaded?)")
            end
        else
            print("[BOOT] ✗ NO ACTIVITY - System may not be booting")
            print("[BOOT]   Possible issues:")
            print("[BOOT]   - Floppy disk not bootable")
            print("[BOOT]   - MAME configuration incorrect")
            print("[BOOT]   - X68000 model mismatch")
        end
    end
end

-- Run monitor
local co = coroutine.create(function()
    monitor_boot()
    emu.wait(1.0)
    manager.machine:exit()
end)

emu.register_periodic(function()
    if coroutine.status(co) ~= "dead" then
        local ok, err = coroutine.resume(co)
        if not ok then
            print("[BOOT] ERROR: " .. tostring(err))
            manager.machine:exit()
        end
    end
end)

print("[BOOT] Boot monitor loaded")
