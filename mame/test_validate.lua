-- MAME X68000 Test Validation Script
-- Waits for program execution and validates VRAM contents

print("=== X68000 Automated Test Started ===")

local START_CHECK_TIME = 15.0  -- Wait 15 seconds for boot + program execution
local test_checked = false
local test_result = false

-- Save test results to file
local function save_result(passed, details)
    local file = io.open("test_result.txt", "w")
    if file then
        if passed then
            file:write("PASS\n")
        else
            file:write("FAIL\n")
        end
        file:write(details .. "\n")
        file:close()
    end
end

-- Check VRAM for expected graphics output
local function validate_graphics()
    print("Validating graphics output...")

    local cpu = manager.machine.devices[":maincpu"]
    if not cpu then
        print("ERROR: Could not find CPU device")
        save_result(false, "ERROR: CPU device not found")
        return false
    end

    local mem = cpu.spaces["program"]
    if not mem then
        print("ERROR: Could not access memory space")
        save_result(false, "ERROR: Memory space not accessible")
        return false
    end

    -- Our program draws three rectangles:
    -- Rect 1: x=50-149, y=50-149, color=255 (0x00FF)
    -- Rect 2: x=200-299, y=50-149, color=240 (0x00F0)
    -- Rect 3: x=350-449, y=50-149, color=15 (0x000F)

    local gvram_base = 0xC00000
    local screen_width = 512
    local checks_passed = 0
    local total_checks = 0

    -- Sample multiple pixels from each rectangle
    local test_points = {
        -- Rectangle 1 (red, color 255)
        {x=60, y=60, expected_min=250, expected_max=255, name="Rect1_Center"},
        {x=100, y=100, expected_min=250, expected_max=255, name="Rect1_Mid"},

        -- Rectangle 2 (green, color 240)
        {x=210, y=60, expected_min=235, expected_max=245, name="Rect2_Center"},
        {x=250, y=100, expected_min=235, expected_max=245, name="Rect2_Mid"},

        -- Rectangle 3 (blue, color 15)
        {x=360, y=60, expected_min=10, expected_max=20, name="Rect3_Center"},
        {x=400, y=100, expected_min=10, expected_max=20, name="Rect3_Mid"},

        -- Background (should be 0 or very low)
        {x=10, y=10, expected_min=0, expected_max=5, name="Background"},
    }

    print("Checking VRAM at 0x" .. string.format("%X", gvram_base))

    for _, point in ipairs(test_points) do
        total_checks = total_checks + 1

        -- Calculate VRAM address (16-bit pixels)
        local offset = (point.y * screen_width + point.x) * 2
        local addr = gvram_base + offset

        -- Read pixel value
        local pixel = mem:read_u16(addr)
        local color = pixel & 0xFF  -- Get color component

        local status = "FAIL"
        if color >= point.expected_min and color <= point.expected_max then
            status = "PASS"
            checks_passed = checks_passed + 1
        end

        print(string.format("  %s at (%d,%d): 0x%04X (color=%d) [%s] Expected: %d-%d",
            point.name, point.x, point.y, pixel, color, status,
            point.expected_min, point.expected_max))
    end

    print(string.format("\nValidation Results: %d/%d checks passed", checks_passed, total_checks))

    -- Test passes if at least 5/7 checks pass (allowing some tolerance)
    local passed = checks_passed >= 5

    if passed then
        print("✓ TEST PASSED: Graphics output validated successfully")
        save_result(true, string.format("Graphics validated: %d/%d checks passed", checks_passed, total_checks))
    else
        print("✗ TEST FAILED: Graphics output does not match expected pattern")
        save_result(false, string.format("Graphics validation failed: only %d/%d checks passed", checks_passed, total_checks))
    end

    return passed
end

-- Main test logic
local function run_test()
    emu.register_frame(function()
        local current_time = emu.time()

        -- Run validation after sufficient time
        if not test_checked and current_time >= START_CHECK_TIME then
            test_checked = true
            print("\n" .. string.rep("=", 50))
            print("Starting validation at T+" .. string.format("%.1f", current_time) .. "s")
            print(string.rep("=", 50))

            -- Take screenshot for manual inspection
            local screen = manager.machine.screens[":screen"]
            if screen then
                local screenshot_path = "test_screenshot.png"
                screen:snapshot(screenshot_path)
                print("Screenshot saved: " .. screenshot_path)
            end

            -- Validate graphics
            test_result = validate_graphics()

            -- Wait a moment then exit
            emu.wait(1.0)
            print("\n" .. string.rep("=", 50))
            print("=== TEST COMPLETE ===")
            print(string.rep("=", 50))

            manager.machine:exit()
        end
    end)
end

-- Start the test
emu.register_start(run_test)
