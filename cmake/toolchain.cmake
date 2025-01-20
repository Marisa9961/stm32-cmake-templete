cmake_minimum_required(VERSION 3.28)

set(CMAKE_SYSTEM_NAME       Generic)
set(CMAKE_SYSTEM_PROCESSOR  arm)

# --------------------------------- Toolchain -------------------------------- #
set(TOOLCHAIN_PREFIX    arm-none-eabi-)

set(CMAKE_C_COMPILER    ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_CXX_COMPILER  ${TOOLCHAIN_PREFIX}g++)
set(CMAKE_ASM_COMPILER  ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_OBJCOPY       ${TOOLCHAIN_PREFIX}objcopy)
set(CMAKE_OBJDUMP       ${TOOLCHAIN_PREFIX}objdump)
set(CMAKE_SIZE          ${TOOLCHAIN_PREFIX}size)

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ------------------------------ Makefile parser ----------------------------- #
include(cmake/utils.cmake)

set(PATH_PREFIX "${CMAKE_SOURCE_DIR}/mcu/")

# Read Makefile generated by STM32CubeMX
file(READ "${PATH_PREFIX}Makefile" STM32CUBEMX_MAKEFILE)
# Strip line continuations
string(REGEX REPLACE "\\\\\\\n" "" STM32CUBEMX_MAKEFILE ${STM32CUBEMX_MAKEFILE})

# ---------------------------------- C Flags --------------------------------- #
extract_makefile_variable("CPU" cpu)
extract_makefile_variable("FPU" fpu)
extract_makefile_variable("FLOAT-ABI" float_abi)
add_compile_options(${cpu} -mthumb ${fpu} ${float_abi})
add_compile_options(-Wall -fdata-sections -ffunction-sections)
add_compile_options($<$<COMPILE_LANGUAGE:ASM>:-x$<SEMICOLON>assembler-with-cpp>) # Enable assembler files preprocessing

# ---------------------------------- LD Flags ------------------------------- #
add_link_options(${cpu} -mthumb ${fpu} ${float_abi})
add_link_options(-specs=nano.specs)
add_link_options(-specs=nosys.specs)
add_link_options(-Wl,-Map=${CMAKE_BINARY_DIR}/target.map,--cref)
add_link_options(-Wl,--gc-sections)
add_link_options(-Wl,--wrap=malloc)
add_link_options(-Wl,--wrap=free)
add_link_options(-Wl,--no-warn-rwx-segments)

# --------------------------------- LD Script  ------------------------------ #
extract_makefile_variable("LDSCRIPT" ld_script)
string(PREPEND ld_script ${PATH_PREFIX})

add_link_options(-T${ld_script})
