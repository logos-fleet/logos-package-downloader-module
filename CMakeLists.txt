cmake_minimum_required(VERSION 3.14)
project(LogosPackageDownloaderModulePlugin LANGUAGES CXX)

# Include the Logos Module CMake helper
if(DEFINED ENV{LOGOS_MODULE_BUILDER_ROOT})
    include($ENV{LOGOS_MODULE_BUILDER_ROOT}/cmake/LogosModule.cmake)
else()
    message(FATAL_ERROR "LogosModule.cmake not found. Set LOGOS_MODULE_BUILDER_ROOT.")
endif()

# WHAT AN ARCHIVE CANNOT CARRY.
#
# On a desktop `package_downloader_lib` is a shared library and the dynamic
# loader resolves curl, OpenSSL and lgx through it. On iOS it is one archive
# with all three folded in (logos-package-downloader's nix/mobile-ios.nix), and
# an archive resolves nothing beyond itself: zlib, the CoreFoundation calls
# lgx's Unicode backend makes, and the Security / SystemConfiguration frameworks
# OpenSSL and curl reach for are the PLATFORM's. All ship in the iOS SDK; there
# is nothing to bundle, only to name.
set(PACKAGE_DOWNLOADER_PLATFORM_LIBS "")
if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    list(APPEND PACKAGE_DOWNLOADER_PLATFORM_LIBS
        z
        "-framework CoreFoundation"
        "-framework Security"
        "-framework SystemConfiguration")
endif()

# Universal module — generated_code/ is picked up automatically by LogosModule.cmake
logos_module(
    NAME package_downloader
    SOURCES
        src/package_downloader_impl.h
        src/package_downloader_impl.cpp
    EXTERNAL_LIBS
        package_downloader_lib
    LINK_LIBRARIES
        ${PACKAGE_DOWNLOADER_PLATFORM_LIBS}
)
