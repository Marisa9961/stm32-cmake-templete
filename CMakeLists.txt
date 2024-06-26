# --------------------------------- Toolchain -------------------------------- #
cmake_minimum_required(VERSION 3.28)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER  arm-none-eabi-gcc)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)

# ---------------------------------- PREFIX ---------------------------------- #

set(TARGET "target")
set(APP_PATH "app")
set(MCU_PATH "mcu")

set(detailed_message OFF)

# ------------------------------- Project Name ------------------------------- #

project(${TARGET} C CXX ASM)
set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 20)

# --------------------------- Optimization level ------------------------------ #

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    add_compile_options(-O0)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
    add_compile_options(-Ofast)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo")
    add_compile_options(-Ofast -g)
elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "MinSizeRel")
    add_compile_options(-Os)
endif ()

# ------------------------------ Makefile parser ----------------------------- #

# Read Makefile generated by STM32CubeMX
file(READ "${MCU_PATH}/Makefile" STM32CUBEMX_MAKEFILE)
# Strip line continuations
string(REGEX REPLACE "\\\\\\\n" "" STM32CUBEMX_MAKEFILE ${STM32CUBEMX_MAKEFILE})

# Function to extract a variable from the Makefile.
function(extract_makefile_variable var_name out_var)
    string(REGEX MATCH "${var_name} = ([^\n]*)" match ${STM32CUBEMX_MAKEFILE})
    if (match)
        string(STRIP "${CMAKE_MATCH_1}" match)
        set(${out_var} ${match} PARENT_SCOPE)
    else()
        set(${out_var} "" PARENT_SCOPE)
    endif()
endfunction()

# Function to extract a list of flag from the Makefile. 
function(extract_makefile_flag var_name out_list leading)
    extract_makefile_variable(${var_name} temp)
    # Split the list into items by spaces 
    string(REPLACE " " ";" temp ${temp})
    # Filter out items that don't start with `leading`
    foreach(item ${temp})
        if (item)
            if (item MATCHES "^${leading}")
                string(REGEX REPLACE "^${leading}" "" item ${item})
                list(APPEND output ${item})
            endif()
        endif()
    endforeach()
    set(${out_list} ${output} PARENT_SCOPE)
endfunction()

# Function to print a variable. 
function(print_var var_name)
    if(detailed_message)
        message(STATUS "${var_name}:")
        foreach(item ${${var_name}})
            if(NOT IS_ABSOLUTE "${item}")
                set(item "${CMAKE_CURRENT_SOURCE_DIR}/${item}")
            endif()
            file(RELATIVE_PATH relative_item ${CMAKE_SOURCE_DIR} ${item})
            message(STATUS "  ${relative_item}")
        endforeach()
    endif()
endfunction()

# ---------------------------------- C Flags --------------------------------- #

extract_makefile_variable("CPU" cpu)
extract_makefile_variable("FPU" fpu)
extract_makefile_variable("FLOAT-ABI" float_abi)
add_compile_options(${cpu} -mthumb ${fpu} ${float_abi})
add_compile_options(-Wall -fdata-sections -ffunction-sections)
add_compile_options($<$<COMPILE_LANGUAGE:ASM>:-x$<SEMICOLON>assembler-with-cpp>) # Enable assembler files preprocessing

extract_makefile_flag("C_DEFS" c_defs "-D")
add_compile_definitions(${c_defs})
print_var(c_defs)

# --------------------------------- Lib Flags -------------------------------- #

extract_makefile_flag("LIBS" libs "-l")
print_var(libs)

# --------------------------------- CMSIS-DSP -------------------------------- #
# Example of using CMSIS-DSP library on CM7 devices. Uncomment the following lines to use CMSIS-DSP.

# include_directories(
#     Drivers/CMSIS/Include
#     Drivers/CMSIS/DSP/Include/
# )
# link_directories(
#     Drivers/CMSIS/DSP/Lib/ARM
#     Drivers/CMSIS/DSP/Lib/GCC
# )
# add_compile_definitions(
#     ARM_MATH_CM7
# )
# list(APPEND libs arm_cortexM7lfdp_math)

# ------------------------- LD Script & Startup ASM -------------------------- #

extract_makefile_variable("LDSCRIPT" ld_script)
extract_makefile_variable("ASM_SOURCES" asm_startup)
set(ld_script "${CMAKE_SOURCE_DIR}/${MCU_PATH}/${ld_script}")
set(asm_startup "${MCU_PATH}/${asm_startup}")
print_var(ld_script)
print_var(asm_startup)

# ---------------------------------- LD Flags ------------------------------- #

add_link_options(-Wl,-gc-sections,-Map=${PROJECT_BINARY_DIR}/${TARGET}.map,--print-memory-usage)
add_link_options(${cpu} -mthumb ${fpu} ${float_abi})
add_link_options(-specs=nano.specs)
add_link_options(-specs=nosys.specs)
add_link_options(-Wl,--no-warn-rwx-segments)
add_link_options(-T${ld_script})

# ------------------------------- LIB Prefix  --------------------------------- #

string(REGEX MATCH "STM32[A-Z][0-9]" DEVICE ${c_defs})
set(CMSIS_PATH "${DEVICE}xx")
set(HAL_PATH "${DEVICE}xx_HAL_Driver")

# ------------------------------- Source Files ------------------------------- #

file(GLOB_RECURSE c_sources 
    "${MCU_PATH}/Core/Src/*.c" 
    "${MCU_PATH}/Drivers/${HAL_PATH}/Src/*.c" 
)
print_var(c_sources)

file(GLOB_RECURSE extra_sources 
    "${APP_PATH}/src/*.c" 
    "${APP_PATH}/src/*.cpp" 
    "${APP_PATH}/src/*.s"
)
print_var(extra_sources)

list(FILTER extra_sources EXCLUDE REGEX ".*Templates.*")
list(APPEND c_sources ${extra_sources})
list(APPEND all_sources ${c_sources} ${extra_sources} ${asm_startup})
list(REMOVE_DUPLICATES all_sources)

# ------------------------------- Include Paths ------------------------------ #

include_directories(
    ${APP_PATH}/inc 
    ${MCU_PATH}/Core/Inc 
    ${MCU_PATH}/Drivers/${HAL_PATH}/Inc 
    ${MCU_PATH}/Drivers/${HAL_PATH}/Legacy/Inc 
    ${MCU_PATH}/Drivers/CMSIS/Include
    ${MCU_PATH}/Drivers/CMSIS/Device/ST/${CMSIS_PATH}/Include 
)

# ----------------------------- Target device -------------------------------- #

string(REGEX MATCH "STM32[A-Z][0-9][0-9][0-9]" TARGET_DEVICE ${c_defs})
message(STATUS "\n-- Target device: ${TARGET_DEVICE} (${CMAKE_BUILD_TYPE})\n--")

# ------------------------------- Executable --------------------------------- #
add_executable(${TARGET}.elf ${all_sources} ${ld_script})

target_link_libraries(${TARGET}.elf ${libs})

set(hex_file ${TARGET}.hex)
set(bin_file ${TARGET}.bin)
set(asm_file ${TARGET}.s)

add_custom_command(TARGET ${TARGET}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -Oihex $<TARGET_FILE:${TARGET}.elf> ${hex_file}
    COMMAND ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${TARGET}.elf> ${bin_file}
    COMMENT "Building ${hex_file} \nBuilding ${bin_file}"
)

# ---------------------------------- Clangd ---------------------------------- #
# Generate .clangd file for clangd language server
if (CMAKE_HOST_WIN32)
    execute_process(COMMAND where arm-none-eabi-gcc OUTPUT_VARIABLE compiler_path OUTPUT_STRIP_TRAILING_WHITESPACE)
    if (NOT compiler_path)
        message(FATAL_ERROR "arm-none-eabi-gcc not found")
    endif()
    # Note that clangd has a bug on Windows where it doesn't handle spaces in the path correctly
    # The best solution is to install the toolchain in a path without spaces. Using scoop is a good option.
    # If you have to use a path with spaces, the following code can convert the path to DOS 8.3 format as a workaround.
    if (compiler_path MATCHES " ")
        execute_process(COMMAND cmd /c for %A in ("${compiler_path}") do @echo %~sA OUTPUT_VARIABLE compiler_path OUTPUT_STRIP_TRAILING_WHITESPACE)
    endif()
    string(REPLACE "\\" "\\\\" compiler_path ${compiler_path})
else()
    execute_process(COMMAND which arm-none-eabi-gcc OUTPUT_VARIABLE compiler_path OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()
print_var(compiler_path)

# Write the .clangd file
# CompileFlags:
#   Compiler: ${compiler_path}

file(WRITE ${CMAKE_SOURCE_DIR}/.clangd "CompileFlags:\n  Compiler: ${compiler_path}\n")

# ---------------------------------- OpenOCD --------------------------------- #
# Generate openocd.cfg file for OpenOCD
# Comment out the following lines if you want to use custom OpenOCD configuration
# Infer the target device from the ld_script
string(REGEX MATCH "STM32[A-Z][0-9]" target_device ${ld_script})
print_var(target_device)
if (NOT target_device)
    message(WARNING "Cannot generate openocd.cfg, failed to detect target device type.")
else()
    string(TOLOWER ${target_device} target_device)
    set(openocd_target "target/${target_device}x.cfg")
    file(WRITE ${CMAKE_SOURCE_DIR}/openocd.cfg "source [find interface/stlink.cfg]\ntransport select hla_swd\nsource [find ${openocd_target}]\n")
endif()
