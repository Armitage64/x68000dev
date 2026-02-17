-- Inject and execute program directly in memory
print("[INJECT] === Direct Code Injection Test ===")

-- Our minimal program (machine code)
local program = {
    0x20, 0x7C, 0x00, 0xC0, 0x00, 0x00,  -- move.l #$C00000, a0
    0x30, 0x3C, 0xFF, 0xFF,               -- move.w #$FFFF, d0
    0x32, 0x3C, 0x01, 0xF4,               -- move.w #500, d1
    -- loop:
    0x30, 0xC0,                           -- move.w d0, (a0)+
    0x51, 0xC9, 0xFF, 0xFC,               -- dbra d1, loop
    -- exit:
    0x30, 0x3C, 0xFF, 0x00,               -- move.w #$FF00, d0
    0x4E, 0x4F, 0xFF, 0x00                -- trap #15, dc.w $FF00
}

local function inject_and_run()
    print("[INJECT] Waiting for system init...")
    emu.wait(5.0)

    print("[INJECT] Accessing CPU...")
    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then
        print("[INJECT] ERROR: No CPU")
        return false
    end

    local mem = cpu.spaces["program"]
    if not mem then
        print("[INJECT] ERROR: No memory")
        return false
    end

    -- Inject program at 0x10000 (safe area in RAM)
    local inject_addr = 0x010000
    print(string.format("[INJECT] Writing %d bytes to 0x%06X...", #program, inject_addr))

    for i, byte in ipairs(program) do
        local addr = inject_addr + i - 1
        local ok, err = pcall(function()
            mem:write_u8(addr, byte)
        end)

        if not ok then
            print(string.format("[INJECT] ERROR writing byte %d: %s", i, tostring(err)))
            return false
        end
    end

    print("[INJECT] Program injected successfully")

    -- Verify injection
    print("[INJECT] Verifying...")
    local verify_ok = true
    for i = 1, math.min(10, #program) do
        local addr = inject_addr + i - 1
        local ok, val = pcall(function() return mem:read_u8(addr) end)
        if ok then
            if val == program[i] then
                print(string.format("[INJECT]   [0x%06X] = 0x%02X ✓", addr, val))
            else
                print(string.format("[INJECT]   [0x%06X] = 0x%02X ✗ (expected 0x%02X)",
                    addr, val, program[i]))
                verify_ok = false
            end
        end
    end

    if not verify_ok then
        print("[INJECT] Verification failed!")
        return false
    end

    print("[INJECT] Verification passed")

    -- Try to set PC to execute our code
    print(string.format("[INJECT] Attempting to execute at 0x%06X...", inject_addr))

    -- Note: Direct PC manipulation may not work in MAME
    -- The program is in memory, but we can't force execution
    -- However, if we can verify it's there, that's progress

    print("[INJECT] Code is in memory but cannot force execution")
    print("[INJECT] Need to solve boot/execution issue")

    -- Wait and check if ANYTHING wrote to GVRAM
    print("[INJECT] Waiting 5 seconds...")
    emu.wait(5.0)

    print("[INJECT] Checking GVRAM...")
    local gvram_activity = 0
    for offset = 0, 0x1000, 0x100 do
        local addr = 0xC00000 + offset
        local ok, val = pcall(function() return mem:read_u16(addr) end)
        if ok and val ~= 0 then
            gvram_activity = gvram_activity + 1
            print(string.format("[INJECT]   GVRAM[0x%06X] = 0x%04X", addr, val))
        end
    end

    print("[INJECT] " .. string.rep("=", 60))
    if gvram_activity > 0 then
        print("[INJECT] ✓ GVRAM HAS ACTIVITY - Something executed!")
        return true
    else
        print("[INJECT] ✗ GVRAM is empty - Nothing executed")
        return false
    end
end

-- Run injection test
local co = coroutine.create(function()
    local result = inject_and_run()
    emu.wait(1.0)
    print("[INJECT] Test complete")
    manager.machine:exit()
end)

emu.register_periodic(function()
    if coroutine.status(co) ~= "dead" then
        local ok, err = coroutine.resume(co)
        if not ok then
            print("[INJECT] ERROR: " .. tostring(err))
            manager.machine:exit()
        end
    end
end)

print("[INJECT] Injection test script loaded")
