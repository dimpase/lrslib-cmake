cmake_minimum_required(VERSION 3.12)
project(lrslib VERSION 0.73 LANGUAGES C)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# ============================================================
# Build options
# ============================================================
option(BUILD_SHARED_LIBS "Build lrslib as shared library" ON)
option(ENABLE_GMP "Enable GMP arbitrary-precision arithmetic" ON)
option(ENABLE_MPI "Enable MPI and build mplrs executable" ON)
option(BUILD_DEMOS "Build demo/test programs" ON)

# Output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# ============================================================
# Include and source setup
# ============================================================
set(LRSLIB_SRC_DIR ${PROJECT_SOURCE_DIR})
set(LRSLIB_DEMO_DIR ${PROJECT_SOURCE_DIR}/demo)
include_directories(${LRSLIB_SRC_DIR})

file(GLOB LRSLIB_SOURCES
     ${LRSLIB_SRC_DIR}/*.c
     ${LRSLIB_SRC_DIR}/*.h)

# ============================================================
# Core library
# ============================================================
add_library(lrslib ${LRSLIB_SOURCES})

if(BUILD_SHARED_LIBS)
  set_target_properties(lrslib PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION 1)
endif()

# ============================================================
# GMP Support
# ============================================================
find_package(GMP REQUIRED)   # or QUIET if optional
if(GMP_FOUND)
  target_include_directories(lrslib PRIVATE ${GMP_INCLUDE_DIRS})
  target_link_libraries(lrslib PRIVATE gmp::gmp)
  add_compile_definitions(USE_GMP)
else()
  message(WARNING "GMP not found — building without GMP support")
endif()

# ============================================================
# Executables
# ============================================================
add_executable(lrs ${LRSLIB_SRC_DIR}/lrs.c)
target_link_libraries(lrs PRIVATE lrslib)

# Optional: MPI version
if(ENABLE_MPI)
  find_package(MPI REQUIRED)
  add_executable(mplrs ${LRSLIB_SRC_DIR}/mplrs.c)
  target_link_libraries(mplrs PRIVATE lrslib MPI::MPI_C)
  target_compile_definitions(mplrs PRIVATE USE_MPI)
endif()

# ============================================================
# Demo programs
# ============================================================
if(BUILD_DEMOS)
  file(GLOB DEMO_SOURCES ${LRSLIB_DEMO_DIR}/*.c)
  foreach(demo_src ${DEMO_SOURCES})
    get_filename_component(demo_name ${demo_src} NAME_WE)
    add_executable(${demo_name} ${demo_src})
    target_link_libraries(${demo_name} PRIVATE lrslib)
  endforeach()
endif()

# ============================================================
# Installation
# ============================================================
install(TARGETS lrslib lrs
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib)

if(ENABLE_MPI)
  install(TARGETS mplrs RUNTIME DESTINATION bin)
endif()

if(BUILD_DEMOS)
  install(DIRECTORY ${LRSLIB_DEMO_DIR}/
    DESTINATION share/lrslib/demos
    FILES_MATCHING PATTERN "*.c")
endif()

install(DIRECTORY ${LRSLIB_SRC_DIR}/
  DESTINATION include/lrslib
  FILES_MATCHING PATTERN "*.h")

# ============================================================
# CMake package config
# ============================================================
include(CMakePackageConfigHelpers)
configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/lrslibConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/lrslibConfig.cmake
  INSTALL_DESTINATION lib/cmake/lrslib
)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/lrslibConfig.cmake
  DESTINATION lib/cmake/lrslib)

# ============================================================
# Summary
# ============================================================
message(STATUS "")
message(STATUS "========== lrslib build configuration ==========")
message(STATUS "Build shared libs  : ${BUILD_SHARED_LIBS}")
message(STATUS "GMP support         : ${ENABLE_GMP}")
message(STATUS "MPI support         : ${ENABLE_MPI}")
message(STATUS "Build demos         : ${BUILD_DEMOS}")
message(STATUS "=================================================")
message(STATUS "")

