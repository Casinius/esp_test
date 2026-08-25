
add_requires("xtensa-esp-elf")
set_plat("cross")
set_arch("xtensa")

toolchain("esp32s3")
    set_kind("standalone")
    add_includedirs(
        "$(toolchaindir)/xtensa-esp32-elf/include",           -- 标准头文件
        "$(toolchaindir)/lib/picolibc/include",               -- picolibc 头文件
        "$(toolchaindir)/xtensa-esp32-elf/sys-include"        -- 系统头文件
    )
    
    on_load(function (toolchain)
        
        for _, pkg in ipairs(toolchain:packages()) do
            local dir = pkg:installdir()
            if dir and os.isdir(dir) then
                toolchain:set("sdkdir", dir)
                break
            end
        end
        local sdkdir = toolchain:sdkdir()
        

        assert(sdkdir, "xtensa-esp-elf package not found!")
        
        local bindir = path.join(sdkdir, "bin")
        local prefix = "xtensa-esp32s3-elf-" 
        toolchain:set("bindir", bindir)
        toolchain:set("toolset", "cc",  prefix .. "gcc")
        toolchain:set("toolset", "cxx", prefix .. "g++")
        toolchain:set("toolset", "ld",  prefix .. "ld")
        toolchain:set("toolset", "sh",  prefix .. "gcc")
        toolchain:set("toolset", "ar",  prefix .. "ar")
        toolchain:set("toolset", "ex",  prefix .. "ar")
        toolchain:set("toolset", "strip", prefix .. "strip")
        toolchain:set("toolset", "as",  prefix .. "as")
        print("is : "..prefix.."as")
        toolchain:set("toolset", "nm",  prefix .. "nm")
        toolchain:set("toolset", "objcopy", prefix .. "objcopy")
        toolchain:set("toolset", "objdump", prefix .. "objdump")
        toolchain:set("toolset", "ranlib",  prefix .. "ranlib")
        toolchain:add("cxflags", "-mlongcalls")
        toolchain:add("cxflags", "-mtext-section-literals")
    
    end)
    
    on_check(function (toolchain)
        return toolchain:sdkdir() ~= nil and 
               os.isfile(path.join(toolchain:sdkdir(), "bin", "xtensa-esp32s3-elf-gcc"))
    end)
toolchain_end()
set_toolchains("esp32s3@xtensa-esp-elf")


--[[
target("firmware")
    set_kind("binary")
    add_files("src/*.c")
    add_ldflags("-T", path.join(bspdir, "ld", "esp32s3.memory.ld"), {force = true})
    add_ldflags("-T", path.join(bspdir, "ld", "esp32s3.rom.ld"), {force = true})
    add_ldflags("-T", path.join(bspdir, "ld", "esp32s3.rom.api.ld"), {force = true})
    add_ldflags("-T", path.join(bspdir, "ld", "esp32s3.rom.libgcc.ld"), {force = true})
    add_ldflags("-T", path.join(bspdir, "ld", "esp32s3.rom.libc.ld"), {force = true})
    add_ldflags("-T", path.join(bspdir, "ld", "esp32s3.rom.newlib.ld"), {force = true})
    add_ldflags("-T", path.join(bspdir, "ld", "esp32s3.peripherals.ld"), {force = true})
target_end()
]]
-- 递归获取 root 下的所有子目录（不含 root 本身）
-- 返回 table，可直接传给 add_includedirs


function recursive_all_dirs(root, exclude_patterns)
    local result = {}
    local function scan(dir)
        for _, entry in ipairs(os.dirs(path.join(dir, "*"))) do
            if os.isdir(entry) then
                -- 排除 stub/sim 目录
                local should_exclude = false
                if exclude_patterns then
                    for _, pattern in ipairs(exclude_patterns) do
                        if entry:find(pattern) then
                            should_exclude = true
                            break
                        end
                    end
                end
                
                if not should_exclude then
                    table.insert(result, entry)
                    scan(entry)
                end
            end
        end
    end
    scan(root)
    return result
end



local bspdir = path.join(os.projectdir(), "esp32s3-bsp")
target("bootloader")
    set_kind("binary")
    add_defines(
    -- 芯片目标宏（ESP-IDF 标准格式）
    "CONFIG_IDF_TARGET_ESP32S3=1",      -- 必须带 =1，很多 #if 用 #ifdef 或 #if CONFIG_IDF_TARGET_ESP32S3
    "CONFIG_IDF_TARGET=\"esp32s3\"",    -- 字符串形式，用于日志/版本信息
    
    -- 你已有的其他宏
    "IDF_VER=\"v6.0.2\"",
    "ESP_PLATFORM",
    "BOOTLOADER_BUILD=1",
    
    -- SOC 特性宏
    "SOC_SPI_FLASH_SUPPORT_SUSPEND=1",
    "SOC_SPI_FLASH_SUPPORT_FAST_READ=1",
    "CONFIG_SPI_FLASH_ROM_DRIVER_PATCH=1",
    "CONFIG_SPI_FLASH_SUPPORT_SUSPEND=1",
    "CONFIG_IDF_FIRMWARE_CHIP_ID=0x0009"
    )
    add_defines("ETS_EFUSE_BLOCK_MAX=EFUSE_BLK_MAX")
    add_files("blsrc/bootloader/subproject/main/*.c")
    add_files("blsrc/bootloader_support/bootloader_flash/src/bootloader_flash_config_esp32s3.c")
    add_files("blsrc/bootloader_support/bootloader_flash/src/bootloader_flash.c")
    add_files("blsrc/bootloader_support/bootloader_flash/src/flash_qio_mode.c")
    add_includedirs("blsrc/sdkconfig/")
    add_includedirs("/home/cyan/Documents/esp_test/blsrc/esp_hal_mspi/include/hal/")
    -- 使用时排除 stubs
    add_includedirs(
    "blsrc/soc/esp32s3/include",        -- 必须包含，且 reset_reasons.h 在此路径下
    "blsrc/soc/esp32s3/register",
    "blsrc/soc/include"
    )
    add_includedirs(recursive_all_dirs("blsrc", {
        "sim/stubs", 
        "stubs",
        "soc/esp32",
        "esp_hal_mspi/esp32/include/",
        "esp_hal_mspi/esp32/include",
        "blsrc/hal/esp32/include/hal",
        "blsrc/hal/esp32/include/",
        "blsrc/hal/esp32",
        "blsrc/hal/linux"
    }))
    -- 可能需要添加的路径（根据你的 ESP-IDF 版本调整）
    add_includedirs("blsrc/hal/include")           -- hal 通用头文件
    add_includedirs("blsrc/hal/esp32s3/include")     -- ESP32-S3 特定的 hal 头文件
    add_includedirs("blsrc/esp_rom/include")         -- ROM 相关定义
    add_includedirs("blsrc/esp_system/include")      -- 系统级定义
    add_ldflags("-T blsrc/bootloader.memory.ld", {force = true})
    add_ldflags("-T blsrc/bootloader.sections.ld", {force = true})
target_end()