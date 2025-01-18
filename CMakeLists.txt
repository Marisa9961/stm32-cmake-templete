cmake_minimum_required(VERSION 3.28)
# ------------------------------ CMake Include ------------------------------- #
include(cmake/utils.cmake)
include(cmake/toolchain.cmake)

# ----------------------------- Project Config -------------------------------- #
set(TARGET "target")
project(${TARGET} LANGUAGES C CXX ASM)

add_executable(${TARGET}.elf)

set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 23)

add_subdirectory(cmake/stm32cubemx)

# ------------------------------ Directory Path ------------------------------ #
set(APP_PATH    "app")
set(BSP_PATH    "bsp")

# ------------------------------- Source Files ------------------------------- #
file(GLOB_RECURSE sources_file 
    "${APP_PATH}/src/*.c" 
    "${BSP_PATH}/Src/*.c" 
)

# ------------------------------ Target Build -------------------------------- #
target_include_directories(${TARGET}.elf PRIVATE
    ${APP_PATH}/inc 
    ${BSP_PATH}/inc 
)

target_sources(${TARGET}.elf PRIVATE
    ${sources_file}
)

target_link_libraries(${TARGET}.elf PRIVATE
    stm32cubemx
)

# ------------------------------- After Build --------------------------------- #
set(hex_file ${TARGET}.hex)
set(bin_file ${TARGET}.bin)
set(asm_file ${TARGET}.s)

add_custom_command(TARGET ${TARGET}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -Oihex $<TARGET_FILE:${TARGET}.elf> ${hex_file}
    COMMAND ${CMAKE_OBJCOPY} -Obinary $<TARGET_FILE:${TARGET}.elf> ${bin_file}
    COMMAND ${CMAKE_OBJDUMP} -d $<TARGET_FILE:${TARGET}.elf> >${asm_file}
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${TARGET}.elf>
)
