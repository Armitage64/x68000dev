-- Comprehensive diagnostic script
print("[DIAG] === X68000 System Diagnostic ===")

local function scan_memory_range(base, size, name)
    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then
        print("[DIAG] ERROR: No CPU found")
        return
    end

    local mem = cpu.spaces["program"]
    if not mem then
        print("[DIAG] ERROR: No memory space")
        return
    end

    print(string.format("[DIAG] Scanning %s (0x%06X, %d bytes)...", name, base, size))

    local non_zero = 0
    local non_ff = 0
    local total = 0
    local sample_values = {}

    -- Sample every 256 bytes
    for offset = 0, size-1, 256 do
        local addr = base + offset
        local ok, val = pcall(function() return mem:read_u8(addr) end)

        if ok then
            total = total + 1
            if val ~= 0 then non_zero = non_zero + 1 end
            if val ~= 0xFF then non_ff = non_ff + 1 end

            -- Save first few non-zero/non-FF values
            if (#sample_values < 10) and (val ~= 0) and (val ~= 0xFF) then
                table.insert(sample_values, string.format("0x%06X=0x%02X", addr, val))
            end
        end
    end

    print(string.format("[DIAG]   Samples: %d, Non-zero: %d, Non-FF: %d",
        total, non_zero, non_ff))

    if #sample_values > 0 then
        print("[DIAG]   Sample values: " .. table.concat(sample_values, ", "))
    end

    return non_zero
end

local function main_diag()
    print("[DIAG] Waiting 15 seconds...")
    emu.wait(15.0)

    print("[DIAG] " .. string.rep("=", 60))
    print("[DIAG] Memory Diagnostic Scan")
    print("[DIAG] " .. string.rep("=", 60))

    -- Scan various memory regions
    scan_memory_range(0x000000, 0x10000, "ROM Area")
    scan_memory_range(0x006800, 0x1000, "Program Load Area")
    scan_memory_range(0x0C0000, 0x10000, "Main RAM")
    scan_memory_range(0xC00000, 0x10000, "GVRAM")
    scan_memory_range(0xE00000, 0x4000, "Text VRAM")
    scan_memory_range(0xE80000, 0x1000, "I/O Registers")

    print("[DIAG] " .. string.rep("=", 60))
    print("[DIAG] Diagnostic complete")
    print("[DIAG] " .. string.rep("=", 60))

    emu.wait(1.0)
    manager.machine:exit()
end

-- Run diagnostic
local co = coroutine.create(main_diag)

emu.register_periodic(function()
    if coroutine.status(co) ~= "dead" then
        local ok, err = coroutine.resume(co)
        if not ok then
            print("[DIAG] ERROR: " .. tostring(err))
            manager.machine:exit()
        end
    end
end)

print("[DIAG] Diagnostic script loaded")
