-- Simple X68000 Test Validation
print("[LUA] Test script starting...")

local test_time = 15.0
local test_done = false

local function check_program_output()
    print("[LUA] Checking program output...")

    -- Try to access CPU and memory
    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then
        print("[LUA] ERROR: Cannot find maincpu device")
        print("[LUA] Available devices:")
        for tag, dev in pairs(manager.machine.devices) do
            print("[LUA]   " .. tag)
        end
        return false
    end

    print("[LUA] Found CPU device")

    -- Try to access memory
    local mem = cpu.spaces["program"]
    if not mem then
        print("[LUA] ERROR: Cannot access program memory space")
        print("[LUA] Available spaces:")
        for name, space in pairs(cpu.spaces) do
            print("[LUA]   " .. name)
        end
        return false
    end

    print("[LUA] Found memory space")

    -- Check VRAM region (X68000 GVRAM is at 0xC00000)
    local gvram_base = 0xC00000
    local test_offset = 0x1000  -- Test at offset to avoid edge cases

    print(string.format("[LUA] Reading VRAM at 0x%X...", gvram_base + test_offset))

    local success, value = pcall(function()
        return mem:read_u16(gvram_base + test_offset)
    end)

    if not success then
        print("[LUA] ERROR: Cannot read VRAM: " .. tostring(value))
        return false
    end

    print(string.format("[LUA] VRAM read successful: 0x%04X", value))

    -- Check multiple locations for non-zero values (indicating graphics were drawn)
    local non_zero_count = 0
    local check_points = {0x1000, 0x2000, 0x3000, 0x4000, 0x5000}

    for _, offset in ipairs(check_points) do
        local addr = gvram_base + offset
        local ok, val = pcall(function() return mem:read_u16(addr) end)
        if ok then
            print(string.format("[LUA] VRAM[0x%X] = 0x%04X", addr, val))
            if val ~= 0 then
                non_zero_count = non_zero_count + 1
            end
        end
    end

    print(string.format("[LUA] Found %d non-zero VRAM locations out of %d checked",
        non_zero_count, #check_points))

    -- If we found any non-zero values, the program likely executed
    if non_zero_count > 0 then
        print("[LUA] ✓ TEST PASSED: Graphics output detected in VRAM")
        return true
    else
        print("[LUA] ✗ TEST FAILED: No graphics output detected")
        return false
    end
end

local function main_loop()
    print("[LUA] Registering frame callback...")

    emu.register_frame(function()
        if test_done then
            return
        end

        local time = emu.time()

        if time >= test_time then
            test_done = true
            print(string.format("[LUA] Test time reached (%.1fs), running validation...", time))

            local result = check_program_output()

            print("[LUA] ========================================")
            if result then
                print("[LUA] FINAL RESULT: TEST PASSED")
            else
                print("[LUA] FINAL RESULT: TEST FAILED")
            end
            print("[LUA] ========================================")

            -- Exit MAME
            print("[LUA] Exiting MAME...")
            manager.machine:exit()
        end
    end)

    print("[LUA] Frame callback registered")
end

print("[LUA] Calling emu.register_start...")
emu.register_start(main_loop)
print("[LUA] Script initialization complete")
