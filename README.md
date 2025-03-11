# 基于CMake实现自动工程管理的STM32工程样例

本仓库基于[stm32cubemx-vscode-cmake](https://github.com/Duanyll/stm32cubemx-vscode-cmake)改进完成，基于个人使用习惯进行了部分改动，并完善了使用样例。

> 本文提供了一种在 VSCode 上基于 CMake 开发 STM32CubeMX 项目的方案，配置了 Clangd 以获得更好的静态检查，并使用 Ninja 加快编译速度。本文的 CMake 配置文件能从 STM32CubeMX 生成的 Makefile 中读取编译参数，能自动同步 CubeMX 中的更改，也能在 CubeMX 重新生成项目时保留自定义选项。本文中的配置文件理论上适用于 Windows, Linux 和 macOS. 由于芯片相关信息是从 Makefile 中读取的, 本文的配置文件理论上适用于所有 STM32CubeMX 支持的 MCU。

## 使用说明

详细的使用可参考上方的原仓库链接，此处仅说明本样例新增的变化。

本样例参考STM32CUBEMX生成CMake项目的形式进行了模块解耦：

    ├── app
    │   ├── src
    │   └── inc
    ├── bsp
    │   ├── src
    │   └── inc
    ├── cmake
    │   ├── stm32cubemx.cmake
    │   ├── toolchain.cmake
    │   └── utils.cmake
    ├── mcu
    │   ├── core
    │   ├── drive
    │   └── ...
    ├── CMakeLists.txt
    └── ...

其中 `./CMakeLists.txt` 作为顶层 **CMake** 构建目标，利用  `cmake/toolchain.cmake` 导入交叉编译工具链，再利用 `cmake/stm32cubemx.cmake` 作为子模块，导入所有 **STM32CubeMX** 所生成的代码，并利用 `cmake/utils.cmake` 中的功能函数自动读取 **STM32CubeMX** 生成的 **Makefile** 文件，最终编译目标结果。

至于为什么在 **STM32CubeMX** 已经有了 **CMake** 构建支持之后仍要使用自行编写的 **CMake** 脚本，是因为官方构建工具对于自行添加三方库并不是十分友好。 **STM32CubeMX** 对于代码及文件目录的删改处理过于简单粗暴，盲目将外部三方库统一存放到 **STM32CubeMX** 的三方库存放处的行为并不会让你的代码目录管理更简洁，在你移除 **STM32CubeMX** 里的三方库时，会导致外部三方库被连带删除。

为了更方便的功能解耦，这里提供了一种将 **STM32CubeMX** 生成的文件隔离在 `mcu` 文件夹内，所有新增的文件都可自行配置在 `app` 、 `bsp` 以及 `third-party` 中，具利于项目管理和代码编写。

## 测试环境

1. 测试平台：Windows 11
2. 样例MCU：STM32H750VBT6
3. ST-Link版本：V2.J44.M29

## 补充

如有任何改进的提议，均可提出`Issue`或是`Pull request`
