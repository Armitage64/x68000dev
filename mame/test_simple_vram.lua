-- X68000 VRAM Test with timer-based approach
print("[LUA] === X68000 VRAM Activity Test ===")

local start_time = nil
local test_done = false

local function check_vram()
    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then
        print("[LUA] ERROR: CPU not found")
        return false
    end

    local mem = cpu.spaces["program"]
    if not mem then
        print("[LUA] ERROR: Memory space not found")
        return false
    end

    local gvram_count = 0
    local sample_points = {0, 100, 500, 1000, 1500, 1999}

    print("[LUA] Checking GVRAM...")
    for _, offset in ipairs(sample_points) do
        local addr = 0xC00000 + (offset * 2)
        local ok, val = pcall(function() return mem:read_u16(addr) end)
        if ok then
            print(string.format("[LUA]   GVRAM[%04d] @ 0x%06X = 0x%04X", offset, addr, val))
            if val ~= 0 then
                gvram_count = gvram_count + 1
            end
        end
    end

    print("[LUA] Checking Text VRAM...")
    local tvram_count = 0
    for i = 0, 500, 100 do
        local addr = 0xE00000 + (i * 2)
        local ok, val = pcall(function() return mem:read_u16(addr) end)
        if ok and val ~= 0 and val ~= 0x0020 then
            print(string.format("[LUA]   TVRAM[%04d] @ 0x%06X = 0x%04X", i, addr, val))
            tvram_count = tvram_count + 1
        end
    end

    print("[LUA] " .. string.rep("=", 60))
    if gvram_count > 0 or tvram_count > 0 then
        print("[LUA] ✓ TEST PASSED")
        print(string.format("[LUA] GVRAM: %d, TVRAM: %d", gvram_count, tvram_count))
    else
        print("[LUA] ✗ TEST FAILED - No VRAM activity")
    end
    print("[LUA] " .. string.rep("=", 60))
end

emu.register_periodic(function()
    if test_done then
        return
    end

    if start_time == nil then
        start_time = os.time()
        print("[LUA] Test started at " .. start_time)
        print("[LUA] Will check VRAM after 100 seconds...")
        print("[LUA] (Please dismiss the warning screen when it appears)")
    end

    local elapsed = os.time() - start_time

    -- Print progress every 20 seconds (avoid spam)
    if elapsed == 20 or elapsed == 40 or elapsed == 60 or elapsed == 80 then
        print(string.format("[LUA] Elapsed: %d seconds...", elapsed))
    end

    -- After 100 seconds, check VRAM
    if elapsed >= 100 then
        print("[LUA] 100 seconds elapsed, checking VRAM now...")
        check_vram()
        test_done = true

        -- Schedule exit after 2 more seconds
        emu.register_periodic(function()
            local exit_elapsed = os.time() - start_time
            if exit_elapsed >= 102 then
                print("[LUA] Exiting MAME...")
                manager.machine:exit()
            end
        end)
    end
end)

print("[LUA] Test initialized with os.time() timing")
