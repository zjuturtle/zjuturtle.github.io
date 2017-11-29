---
title: CMake 与 Google Test
date: 2017-11-29 14:18:18
categories:
 - TechChatter
tags:
 - CMake
 - GTest
 - Google Test
 - C++
---

公司有一部分的 C++ 库是我编写的，但一直没有系统的测试。只是在写出来的时候随便写了点测试代码，通过就算完事，当时的测试代码也没有留下来。最近做库的扩写，顺带就想吧测试框架补上。我的 C++ 工程是用 CMake 来架构的，因此就记录一下如何用 CMake 使用 Google Test。

<!--more-->

## Google Test 安装

去 GitHub 下载 [Google Test](https://github.com/google/googletest) 。当前的最新稳定版本是 1.8.0。直接下载下来的源码 包含了 Google Test 和 Google Mock 两个项目，实际上只需要 Google Test 文件夹内的内容就可以了。

按照[官方文档](https://github.com/google/googletest/blob/master/googletest/docs/Primer.md)的指引，使用 Google Test 的最佳方式是先编译 Google Test 项目成一个静态库，然后写测试代码，链接过去。

Google Test 直接使用 CMake 就可以 build 啦。

~~~bash
mkdir build
cd build
cmake -D $(GTEST_DIR)  # Where you put googletest
make
~~~

在默认情况下，会生成 `gtest` 和 `gtest_main` 两个项目。两个都是静态库，但后一个包含 main 函数。

注意在 Google Test 的 `CMakeLists.txt` 文件里还有 `install` 的命令

~~~cmake
install(TARGETS gtest gtest_main
  DESTINATION lib)
install(DIRECTORY ${gtest_SOURCE_DIR}/include/gtest
  DESTINATION include)
~~~

那么只要运行

~~~bash
make install
~~~

就可以直接将库安装在本地系统上了。

## Google Test 接入

假设我们的目录结构是这样的（我的库只有头文件）

~~~tree
src
|- foo.h
tests
|- CMakeLists.txt
|- fooTest.cpp
CMakeLists.txt
~~~

那么我们在最外层的 `CMakeLists.txt` 里可以这么写

~~~cmake
cmake_minimum_required(VERSION 3.0)

project(foo)
add_subdirectory(tests)
~~~

在 `tests/CMakeLists.txt` 里参照 [CMake指引](https://cmake.org/cmake/help/latest/module/FindGTest.html) 则可以这么写

~~~cmake
cmake_minimum_required(VERSION 3.0)

enable_testing()

find_package(GTest REQUIRED)
include_directories(${GTEST_INCLUDE_DIR})
add_executable(Footest example.cpp)
target_link_libraries(Footest ${GTEST_BOTH_LIBRARIES})

add_test(
        NAME Footest
        COMMAND Footest
)
~~~

在之前的 Google Test 安装过程中，其实 `install` 里面没有安装 `FindGTest.cmake`。这个文件是 CMake 自己提供的。Mac 系统下在 `${CMAKE_ROOT}/Modules` 下的。

还有另外一种方式，即通过[直接的源码接入](https://github.com/google/googletest/blob/master/googletest/README.md#incorporating-into-an-existing-cmake-project)，Google 推荐，这里就不详细叙述了。

