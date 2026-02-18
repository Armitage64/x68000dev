-- Hello World test: uses os.time() for real-time tracking
-- Waits for the system to actually boot, then checks for text/graphics output
print("[LUA] Hello World test starting")
print("[LUA] Using real-time (os.time) tracking - not emulated time")

local start_time = nil
local test_done = false
local last_logged = -1
local WAIT_SECONDS = 70

emu.register_periodic(function()
    if test_done then return end

    if start_time == nil then
        start_time = os.time()
        print("[LUA] Timer started, will check after " .. WAIT_SECONDS .. " real seconds")
        return
    end

    local elapsed = os.time() - start_time

    -- Print progress once per 10-second mark (not every frame at that second)
    if elapsed > 0 and elapsed % 10 == 0 and elapsed ~= last_logged then
        last_logged = elapsed
        local cpu = manager.machine.devices[":maincpu"]
        local pc_str = "?"
        if cpu then
            local ok, pc = pcall(function() return cpu.state["PC"].value end)
            if ok then
                pc_str = string.format("0x%08X", pc)
                -- Indicate if we're in ROM (not booted) or RAM (booted)
                if pc >= 0xFF0000 then
                    pc_str = pc_str .. " (BIOS - still booting)"
                else
                    pc_str = pc_str .. " (RAM - OS running)"
                end
            end
        end
        print(string.format("[LUA] t=%ds PC=%s", elapsed, pc_str))
    end

    if elapsed < WAIT_SECONDS then return end

    -- Time's up - run the test
    test_done = true
    print("[LUA] " .. string.rep("=", 60))
    print("[LUA] Checking memory after " .. WAIT_SECONDS .. " seconds...")
    print("[LUA] " .. string.rep("=", 60))

    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then
        print("[LUA] ERROR: no CPU found")
        manager.machine:exit()
        return
    end

    local mem = cpu.spaces["program"]
    if not mem then
        print("[LUA] ERROR: no memory space")
        manager.machine:exit()
        return
    end

    -- Diagnostic: print TRAP #15 vector (at 0x00BC = vector 47)
    do
        local ok, trap15 = pcall(function() return mem:read_u32(0x0000BC) end)
        if ok then
            print(string.format("[LUA] TRAP#15 vector @ 0x0000BC = 0x%08X", trap15))
        else
            print("[LUA] TRAP#15 vector read failed")
        end
    end

    -- Diagnostic: check our program's RAM flag (written before any TRAP call)
    do
        local ok, flag = pcall(function() return mem:read_u32(0x070000) end)
        if ok then
            print(string.format("[LUA] RAM flag @ 0x070000 = 0x%08X", flag))
        end
    end

    -- Diagnostic: print raw TVRAM[0] even if zero
    do
        local ok, val = pcall(function() return mem:read_u16(0xE00000) end)
        if ok then
            print(string.format("[LUA] TVRAM[0] @ 0xE00000 = 0x%04X", val))
        else
            print("[LUA] TVRAM[0] read failed")
        end
    end

    -- Check TVRAM - scan first 256 chars of text screen (96 cols x ~3 rows)
    local tvram_hits = 0
    for i = 0, 255 do
        local addr = 0xE00000 + i * 2
        local ok, val = pcall(function() return mem:read_u16(addr) end)
        if ok and val ~= 0 then
            tvram_hits = tvram_hits + 1
            if tvram_hits <= 5 then
                print(string.format("[LUA]   TVRAM[%d] @ 0x%06X = 0x%04X", i, addr, val))
            end
        end
    end

    -- Check GVRAM (graphics output)
    local gvram_hits = 0
    for i = 0, 19 do
        local addr = 0xC00000 + i * (0x80000 // 20)
        local ok, val = pcall(function() return mem:read_u16(addr) end)
        if ok and val ~= 0 then
            gvram_hits = gvram_hits + 1
        end
    end

    -- Check program area
    local ram_hits = 0
    for i = 0, 15 do
        local addr = 0x006800 + i * 4
        local ok, val = pcall(function() return mem:read_u16(addr) end)
        if ok and val ~= 0 then
            ram_hits = ram_hits + 1
        end
    end

    -- Also check low RAM (0x000400 - above exception vectors, OS work area)
    local lowram_hits = 0
    for i = 0x80, 0x100, 4 do
        local ok, val = pcall(function() return mem:read_u16(i) end)
        if ok and val ~= 0 then lowram_hits = lowram_hits + 1 end
    end

    print(string.format("[LUA] TVRAM hits: %d", tvram_hits))
    print(string.format("[LUA] GVRAM hits: %d", gvram_hits))
    print(string.format("[LUA] Program area (0x6800) hits: %d", ram_hits))
    print(string.format("[LUA] Low RAM (work area) hits: %d", lowram_hits))

    -- Take a screenshot
    local screen = manager.machine.screens[":screen"]
    if screen then
        screen:snapshot("hello_result.png")
        print("[LUA] Screenshot saved: hello_result.png")
    end

    print("[LUA] " .. string.rep("=", 60))
    if tvram_hits > 0 or gvram_hits > 0 then
        print("[LUA] TEST PASSED")
        print("[LUA] Output detected in " ..
            (tvram_hits > 0 and "TVRAM (text)" or "GVRAM (graphics)"))
    elseif ram_hits > 0 then
        print("[LUA] TEST PARTIAL")
        print("[LUA] Program loaded at 0x6800 but no screen output detected")
    elseif lowram_hits > 0 then
        print("[LUA] TEST FAILED")
        print("[LUA] OS work area has data - Human68k may have booted but program did not run")
    else
        print("[LUA] TEST FAILED")
        print("[LUA] No activity - system may not have booted")
    end
    print("[LUA] " .. string.rep("=", 60))

    manager.machine:exit()
end)

print("[LUA] Script loaded")
