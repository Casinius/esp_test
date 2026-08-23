
add_requires("xtensa-esp-elf")
set_plat("cross")
set_arch("xtensa")

target("firmware")
    set_kind("binary")
    add_files("src/*.c")
    add_packages("xtensa-esp-elf")
    set_toolchains("gnu-rm@xtensa-esp-elf")