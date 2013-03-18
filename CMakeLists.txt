cmake_minimum_required (VERSION 2.8)
project (WiiStep)

# Add wsinstall target
add_subdirectory(wsinstall)

# Add libobjc2 (and provide PPC-eabi rule-set)
set(WIISTEP TRUE)
set(WIISTEP_PLATFORM "libogc")
add_subdirectory(gnustep-libobjc2 EXCLUDE_FROM_ALL)



# Add command to run wsinstall to download needed binaries
if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
add_custom_command(OUTPUT wsinstall-ran COMMAND ${PROJECT_SOURCE_DIR}/LaunchWSInstallOSX.sh ARGS $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ${PROJECT_BINARY_DIR}
MAIN_DEPENDENCY wsinstall
COMMENT "Now running wsinstall...")
else()
add_custom_command(OUTPUT wsinstall-ran $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ARGS ${PROJECT_BINARY_DIR}
MAIN_DEPENDENCY wsinstall
COMMENT "Now running wsinstall...")
endif()

# Temporary custom target to test custom command
add_custom_target(WiiStep ALL DEPENDS wsinstall-ran objc-static)
