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
option(USE_LRSARITH "Use built-in lrsarith multiple-precision back-end instead of GMP" OFF)

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
)

# Core library
add_library(lrslib ${LRSLIB_SOURCES})
if(BUILD_SHARED_LIBS)
  set_target_properties(lrslib PROPERTIES
     VERSION ${PROJECT_VERSION}
     SOVERSION 1
  )
endif()

# ============================================================
# Arithmetic backend selection
# ============================================================
set(LRSARITH_DIR "${PROJECT_SOURCE_DIR}/lrsarith-011")

# Always add lrsarith include directory (contains lrsgmp.h and lrsmp.h)
target_include_directories(lrslib PRIVATE ${LRSARITH_DIR})

if(ENABLE_GMP AND NOT USE_LRSARITH)
  find_package(PkgConfig QUIET)
  if(PkgConfig_FOUND)
    pkg_check_modules(GMP_PKG QUIET gmp)
  endif()

  if(GMP_PKG_FOUND)
    message(STATUS "Using GMP backend")
    target_include_directories(lrslib PRIVATE ${GMP_PKG_INCLUDE_DIRS})
    target_link_libraries(lrslib PRIVATE ${GMP_PKG_LIBRARIES})
    target_compile_definitions(lrslib PRIVATE GMP)
  else()
    message(WARNING "GMP not found via pkg-config — falling back to built-in lrsarith")
    set(USE_LRSARITH ON)
  endif()
endif()

if(USE_LRSARITH)
  message(STATUS "Using built-in lrsarith backend")
  # Path to lrsarith-011 directory (adjust if necessary)
  target_include_directories(lrslib PRIVATE ${PROJECT_SOURCE_DIR}/../lrsarith-011)
  target_sources(lrslib PRIVATE ${PROJECT_SOURCE_DIR}/../lrsarith-011/lrsmp.c)
  # target_compile_definitions(lrslib PRIVATE ARITH=\"lrsmp.h\")
endif()

# ============================================================
# Executables
# ============================================================
add_executable(lrs ${LRSLIB_SRC_DIR}/lrs.c)
target_link_libraries(lrs PRIVATE lrslib)

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
message(STATUS "Build shared libs : ${BUILD_SHARED_LIBS}")
message(STATUS "Using GMP backend : ${ENABLE_GMP}")
message(STATUS "Using built-in lrsarith: ${USE_LRSARITH}")
message(STATUS "MPI support       : ${ENABLE_MPI}")
message(STATUS "Build demos       : ${BUILD_DEMOS}")
message(STATUS "=================================================")
message(STATUS "")

