-- Direct X68000 Test Validation (no callbacks)
print("[LUA] === X68000 Direct Test Script ===")

-- Wait for emulation to start
emu.wait(15.0)
print("[LUA] 15 seconds elapsed, checking VRAM...")

-- Get CPU device
print("[LUA] Looking for CPU device...")
local cpu = manager.machine.devices[":maincpu"]

if not cpu then
    print("[LUA] ERROR: Cannot find :maincpu")
    print("[LUA] Available devices:")
    for tag, dev in pairs(manager.machine.devices) do
        print("[LUA]   Device: " .. tag)
    end
    os.exit(1)
end

print("[LUA] Found CPU: " .. cpu.tag)

-- Get memory space
print("[LUA] Accessing memory space...")
local mem = cpu.spaces["program"]

if not mem then
    print("[LUA] ERROR: Cannot access program memory")
    print("[LUA] Available memory spaces:")
    for name, space in pairs(cpu.spaces) do
        print("[LUA]   Space: " .. name)
    end
    os.exit(1)
end

print("[LUA] Got memory space")

-- Check VRAM
print("[LUA] Checking VRAM at 0xC00000...")
local gvram_base = 0xC00000
local found_graphics = false
local non_zero_count = 0

-- Sample various VRAM locations
for i = 0, 10 do
    local offset = i * 0x1000
    local addr = gvram_base + offset
    local ok, val = pcall(function() return mem:read_u16(addr) end)

    if ok then
        print(string.format("[LUA]   VRAM[0x%06X] = 0x%04X", addr, val))
        if val ~= 0 then
            non_zero_count = non_zero_count + 1
            found_graphics = true
        end
    else
        print(string.format("[LUA]   ERROR reading 0x%06X: %s", addr, tostring(val)))
    end
end

print(string.format("[LUA] Found %d non-zero values in VRAM", non_zero_count))

-- Print result
print("[LUA] ========================================")
if found_graphics then
    print("[LUA] TEST PASSED: Graphics detected in VRAM")
    print("[LUA] ========================================")
else
    print("[LUA] TEST FAILED: No graphics detected")
    print("[LUA] ========================================")
end

-- Exit
print("[LUA] Test complete, exiting...")
manager.machine:exit()
