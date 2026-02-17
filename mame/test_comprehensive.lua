-- Comprehensive X68000 Test Validation
print("[LUA] === X68000 Comprehensive Test ===")

local function check_memory_region(base, size, name)
    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then return 0 end

    local mem = cpu.spaces["program"]
    if not mem then return 0 end

    local non_zero = 0
    local sample_count = math.min(20, size // 0x100)

    print(string.format("[LUA] Checking %s (0x%06X, %d samples)...", name, base, sample_count))

    for i = 0, sample_count - 1 do
        local offset = i * (size // sample_count)
        local addr = base + offset
        local ok, val = pcall(function() return mem:read_u16(addr) end)

        if ok and val ~= 0 then
            non_zero = non_zero + 1
            print(string.format("[LUA]   [%s+0x%04X] = 0x%04X", name, offset, val))
        end
    end

    return non_zero
end

local function test_main()
    print("[LUA] Waiting 40 seconds for system boot and execution...")
    emu.wait(40.0)

    print("[LUA] " .. string.rep("=", 60))
    print("[LUA] Beginning System Analysis...")
    print("[LUA] " .. string.rep("=", 60))

    -- Check various memory regions
    local gvram_hits = check_memory_region(0xC00000, 0x80000, "GVRAM")
    local tvram_hits = check_memory_region(0xE00000, 0x80000, "Text VRAM")
    local ram_hits = check_memory_region(0x006800, 0x1000, "Program Area")

    print("[LUA] " .. string.rep("-", 60))
    print(string.format("[LUA] GVRAM activity: %d non-zero locations", gvram_hits))
    print(string.format("[LUA] Text VRAM activity: %d non-zero locations", tvram_hits))
    print(string.format("[LUA] Program area activity: %d non-zero locations", ram_hits))
    print("[LUA] " .. string.rep("-", 60))

    -- More detailed VRAM check for our specific rectangles
    local cpu = manager.machine.devices[":maincpu"]
    if cpu then
        local mem = cpu.spaces["program"]
        if mem then
            print("[LUA] Detailed GVRAM check for expected graphics:")

            -- Our program should draw rectangles at:
            -- Rect 1: (50-149, 50-149)
            -- Rect 2: (200-299, 50-149)
            -- Rect 3: (350-449, 50-149)

            local screen_width = 512
            local test_points = {
                {x=100, y=100, name="Rect1"},
                {x=250, y=100, name="Rect2"},
                {x=400, y=100, name="Rect3"},
            }

            local graphics_found = false
            for _, pt in ipairs(test_points) do
                local offset = (pt.y * screen_width + pt.x) * 2
                local addr = 0xC00000 + offset
                local ok, val = pcall(function() return mem:read_u16(addr) end)

                if ok then
                    print(string.format("[LUA]   %s (%d,%d) [0x%06X] = 0x%04X",
                        pt.name, pt.x, pt.y, addr, val))
                    if val ~= 0 then
                        graphics_found = true
                    end
                end
            end

            print("[LUA] " .. string.rep("=", 60))
            if graphics_found or gvram_hits > 0 then
                print("[LUA] ✓ TEST PASSED")
                print("[LUA] Graphics output detected - program executed successfully")
            else
                print("[LUA] ✗ TEST FAILED  ")
                print("[LUA] No graphics detected - program may not have executed")
                print("[LUA] ")
                print("[LUA] Possible causes:")
                print("[LUA]   - AUTOEXEC.BAT not running the program")
                print("[LUA]   - Program format incompatible with Human68k")
                print("[LUA]   - Program crashing before drawing")
                print("[LUA]   - Graphics mode not set correctly")
            end
            print("[LUA] " .. string.rep("=", 60))

            return graphics_found or gvram_hits > 0
        end
    end

    return false
end

-- Run in coroutine
local co = coroutine.create(function()
    test_main()
    emu.wait(1.0)
    print("[LUA] Exiting MAME...")
    manager.machine:exit()
end)

emu.register_periodic(function()
    if coroutine.status(co) ~= "dead" then
        local ok, err = coroutine.resume(co)
        if not ok then
            print("[LUA] ERROR: " .. tostring(err))
            manager.machine:exit()
        end
    end
end)

print("[LUA] Test script initialized and running")
