cmake_minimum_required (VERSION 2.8)
project (WiiStep)

# Add wsinstall target
add_subdirectory(wsinstall)

# Add command to run wsinstall to download needed binaries
if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
add_custom_target(wsinstall-ran ALL ${PROJECT_SOURCE_DIR}/LaunchWSInstall.sh $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ${PROJECT_BINARY_DIR}
DEPENDS wsinstall
COMMENT "Now running wsinstall...")
else()
add_custom_target(wsinstall-ran ALL $<TARGET_FILE_DIR:wsinstall>/$<TARGET_FILE_NAME:wsinstall> ${PROJECT_BINARY_DIR}
DEPENDS wsinstall
COMMENT "Now running wsinstall...")
endif()
