
add_requires("xtensa-esp-elf")
set_plat("cross")
set_arch("xtensa")

toolchain("esp32s3")
    set_kind("standalone")
    
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


function recursive_all_dirs(root)
    local result = {}
    local function scan(dir)
        for _, entry in ipairs(os.dirs(path.join(dir, "*"))) do
            if os.isdir(entry) then
                table.insert(result, entry)
                --print(entry)
                scan(entry)   -- 继续递归
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
    "__ESP32_S3__",
    "IDF_VER=\"v6.0.2\"",
    "CONFIG_ESP32_S3",        -- 开启 S3 相关代码分支
    "CONFIG_IDF_TARGET_ESP32S3"
)

    add_files("blsrc/bootloader/subproject/main/*.c")
    add_files("blsrc/bootloader_support/bootloader_flash/src/bootloader_flash_config_esp32s3.c")
    add_files("blsrc/bootloader_support/bootloader_flash/src/bootloader_flash.c")
    add_files("blsrc/bootloader_support/bootloader_flash/src/flash_qio_mode.c")
    add_includedirs("blsrc/sdkconfig/")
    add_includedirs(recursive_all_dirs("blsrc"))
    add_ldflags("-T blsrc/bootloader.memory.ld", {force = true})
    add_ldflags("-T blsrc/bootloader.sections.ld", {force = true})
target_end()