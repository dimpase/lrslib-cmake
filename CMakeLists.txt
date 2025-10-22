cmake_minimum_required(VERSION 3.12)
project(lrslib VERSION 0.73 LANGUAGES C)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# ============================================================
# Build options
# ============================================================
option(BUILD_SHARED_LIBS "Build lrslib as shared library" ON)
option(ENABLE_GMP "Enable GMP arbitrary-precision arithmetic" ON)
option(ENABLE_MPI "Enable MPI and build mplrs executable" OFF)
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

file(GLOB ALL_C_SOURCES ${LRSLIB_SRC_DIR}/*.c)
file(GLOB ARITH_SOURCES ${LRSARITH_DIR}/*.c)

# rat2float seems to be unused, not in makefike
list(FILTER ALL_C_SOURCES EXCLUDE REGEX ".*/rat2float\\.c$")

# Remove MPI-related source files if MPI is disabled
if(NOT ENABLE_MPI)
    list(FILTER ALL_C_SOURCES EXCLUDE REGEX ".*/mplrs\\.c$")
endif()

# Exclude sources that define executables (contain main())
set(EXCLUDE_PATTERNS
    "${LRSLIB_SRC_DIR}/lrs.c"
    "${LRSLIB_SRC_DIR}/mplrs.c"
    "${LRSLIB_SRC_DIR}/2nash.c"
    "${LRSLIB_SRC_DIR}/chdemo.c"
    "${LRSLIB_SRC_DIR}/hvref.c"
    "${LRSLIB_SRC_DIR}/inedel.c"
    "${LRSLIB_SRC_DIR}/lpdemo.c"
    "${LRSLIB_SRC_DIR}/lpdemo1.c"
    "${LRSLIB_SRC_DIR}/lpdemo2.c"
    "${LRSLIB_SRC_DIR}/lrsnash.c"
    "${LRSLIB_SRC_DIR}/nashdemo.c"
    "${LRSLIB_SRC_DIR}/polyv.c"
    "${LRSLIB_SRC_DIR}/setupnash.c"
    "${LRSLIB_SRC_DIR}/setupnash2.c"
    "${LRSLIB_SRC_DIR}/vedemo.c"
    "${LRSARITH_DIR}/coll.c"
    "${LRSARITH_DIR}/fixed.c"
    "${LRSARITH_DIR}/hybrid.c"
    "${LRSARITH_DIR}/test.c"
)

set(LRSLIB_SOURCES ${ALL_C_SOURCES})
list(APPEND LRSLIB_SOURCES ${ARITH_SOURCES})
list(REMOVE_ITEM LRSLIB_SOURCES ${EXCLUDE_PATTERNS})

# Core library
add_library(lrslib ${LRSLIB_SOURCES})
target_compile_definitions(lrslib PRIVATE SIGNALS)
if(BUILD_SHARED_LIBS)
  set_target_properties(lrslib PROPERTIES
     VERSION ${PROJECT_VERSION}
     SOVERSION 1
  )
endif()

# Enable MPI if available

if(ENABLE_MPI)
    find_package(MPI QUIET)
    if(MPI_FOUND)
        message(STATUS "MPI found: ${MPI_C_INCLUDE_DIRS}")
        target_include_directories(lrslib PRIVATE ${MPI_C_INCLUDE_DIRS})
        target_link_libraries(lrslib PRIVATE ${MPI_C_LIBRARIES})
        target_compile_definitions(lrslib PRIVATE HAVE_MPI)
    else()
        message(WARNING "MPI not found, but ENABLE_MPI=ON. Disabling MPI support.")
	set(ENABLE_MPI OFF CACHE BOOL "Enable MPI support" FORCE)
    endif()
else()
    message(STATUS "MPI disabled (ENABLE_MPI=OFF)")
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
target_include_directories(lrs PRIVATE ${LRSLIB_SRC_DIR} ${LRSARITH_DIR})

if(ENABLE_MPI)
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

