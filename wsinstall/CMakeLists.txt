cmake_minimum_required(VERSION 2.8)
project(wsinstall)

# Xcode-style project-header resolution
include_directories(ScreenClasses DownloaderClasses)

# Sub-project classes (defined as static library targets)
add_subdirectory(ScreenClasses)

# Lazy me :)
add_definitions(-fobjc-arc)

add_executable(wsinstall
WSInstall.m
main.m)

find_library(FOUNDATION_LIBRARY Foundation)

target_link_libraries(wsinstall
WSInstallScreens
curl
readline
ncurses
${FOUNDATION_LIBRARY})

