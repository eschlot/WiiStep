cmake_minimum_required(VERSION 2.8)
project(wsinstall)

include_directories(ScreenClasses DownloaderClasses)

# Xcode-style project-header resolution
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
edit
ncurses
${FOUNDATION_LIBRARY})

