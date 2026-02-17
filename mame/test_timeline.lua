-- Timeline monitoring - check memory at multiple intervals
print("[TIME] === Boot Timeline Monitor ===")

local function check_memory_snapshot()
    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then return nil end

    local mem = cpu.spaces["program"]
    if not mem then return nil end

    local snapshot = {
        text_vram = 0,
        gvram = 0,
        program = 0,
        time = emu.time()
    }

    -- Check Text VRAM (boot messages)
    for i = 0, 1000, 100 do
        local ok, val = pcall(function() return mem:read_u8(0xE00000 + i) end)
        if ok and val ~= 0 and val ~= 0xFF then
            snapshot.text_vram = snapshot.text_vram + 1
        end
    end

    -- Check GVRAM
    for i = 0, 1000, 100 do
        local ok, val = pcall(function() return mem:read_u16(0xC00000 + i) end)
        if ok and val ~= 0 then
            snapshot.gvram = snapshot.gvram + 1
        end
    end

    -- Check program area
    for i = 0, 100, 10 do
        local ok, val = pcall(function() return mem:read_u8(0x6800 + i) end)
        if ok and val ~= 0 and val ~= 0xFF then
            snapshot.program = snapshot.program + 1
        end
    end

    return snapshot
end

local function monitor_timeline()
    print("[TIME] Monitoring memory over time...")
    print("[TIME] Time(s) | TextVRAM | GVRAM | Program | Status")
    print("[TIME] " .. string.rep("-", 60))

    -- Check at 5-second intervals for 60 seconds
    for t = 5, 60, 5 do
        emu.wait(5.0)

        local snap = check_memory_snapshot()
        if snap then
            local status = "Waiting..."
            if snap.text_vram > 5 then
                status = "BOOT DETECTED!"
            elseif snap.gvram > 5 then
                status = "GRAPHICS!"
            elseif snap.program > 3 then
                status = "Code loaded"
            end

            print(string.format("[TIME] %6.1f | %8d | %5d | %7d | %s",
                snap.time, snap.text_vram, snap.gvram, snap.program, status))
        end
    end

    print("[TIME] " .. string.rep("-", 60))
    print("[TIME] Timeline monitoring complete")

    -- Final check
    local final = check_memory_snapshot()
    if final and (final.text_vram > 0 or final.gvram > 0) then
        print("[TIME] ✓ ACTIVITY DETECTED")
        if final.text_vram > 5 then
            print("[TIME]   Boot messages present in Text VRAM")
        end
        if final.gvram > 5 then
            print("[TIME]   Graphics present in GVRAM")
        end
    else
        print("[TIME] ✗ NO ACTIVITY - System did not boot or execute")
    end
end

-- Run timeline monitor
local co = coroutine.create(function()
    monitor_timeline()
    emu.wait(1.0)
    manager.machine:exit()
end)

emu.register_periodic(function()
    if coroutine.status(co) ~= "dead" then
        local ok, err = coroutine.resume(co)
        if not ok then
            print("[TIME] ERROR: " .. tostring(err))
            manager.machine:exit()
        end
    end
end)

print("[TIME] Timeline monitor loaded")
