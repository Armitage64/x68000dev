-- X68000 Test Validation using Coroutine
print("[LUA] === X68000 Test Script (Coroutine Version) ===")

local function test_main()
    print("[LUA] Test coroutine started")
    print("[LUA] Waiting 15 seconds for boot and program execution...")

    -- Wait for boot and program to run
    emu.wait(15.0)

    print("[LUA] Wait complete, beginning validation...")

    -- Get CPU device
    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then
        print("[LUA] ERROR: Cannot find CPU device")
        return false
    end

    print("[LUA] Found CPU device: " .. cpu.tag)

    -- Get memory space
    local mem = cpu.spaces["program"]
    if not mem then
        print("[LUA] ERROR: Cannot access program memory space")
        return false
    end

    print("[LUA] Got memory space, checking VRAM...")

    -- Check VRAM at 0xC00000
    local gvram_base = 0xC00000
    local non_zero_count = 0
    local total_checked = 0

    -- Sample VRAM at various offsets
    local test_offsets = {
        0x0000, 0x1000, 0x2000, 0x3000, 0x4000,
        0x5000, 0x6000, 0x7000, 0x8000, 0x9000
    }

    for _, offset in ipairs(test_offsets) do
        local addr = gvram_base + offset
        local ok, val = pcall(function() return mem:read_u16(addr) end)

        if ok then
            total_checked = total_checked + 1
            print(string.format("[LUA]   VRAM[0x%06X] = 0x%04X", addr, val))
            if val ~= 0 then
                non_zero_count = non_zero_count + 1
            end
        else
            print(string.format("[LUA]   ERROR reading 0x%06X", addr))
        end
    end

    print(string.format("[LUA] Validation complete: %d/%d locations contain graphics data",
        non_zero_count, total_checked))

    -- Determine pass/fail
    print("[LUA] " .. string.rep("=", 50))
    if non_zero_count > 0 then
        print("[LUA] ✓ TEST PASSED")
        print("[LUA] Program executed and drew graphics to VRAM")
        print("[LUA] " .. string.rep("=", 50))
        return true
    else
        print("[LUA] ✗ TEST FAILED")
        print("[LUA] No graphics detected in VRAM")
        print("[LUA] " .. string.rep("=", 50))
        return false
    end
end

-- Run test in coroutine
local co = coroutine.create(function()
    local result = test_main()
    print("[LUA] Exiting MAME...")
    manager.machine:exit()
end)

-- Start the coroutine
emu.register_periodic(function()
    if coroutine.status(co) ~= "dead" then
        local ok, err = coroutine.resume(co)
        if not ok then
            print("[LUA] ERROR in coroutine: " .. tostring(err))
            manager.machine:exit()
        end
    end
end)

print("[LUA] Test coroutine registered and started")
