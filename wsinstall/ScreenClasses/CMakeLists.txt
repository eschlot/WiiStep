cmake_minimum_required(VERSION 2.8)
project(wsinstall)

add_subdirectory(Utilities)
include_directories(Utilities)

add_definitions(-fobjc-arc)

add_library(WSInstallScreens
MainScreen.m
HeaderWindow.m
FooterWindow.m
DirPromptWindow.m
ProgressWindow.m
MultiLineMessageWindow.m
NeededDependenciesReportWindow.m)

target_link_libraries(WSInstallScreens
WSInstallScreenUtilities)
