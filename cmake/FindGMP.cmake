# Try to find GMP via pkg-config first
find_package(PkgConfig QUIET)

if(PkgConfig_FOUND)
  pkg_check_modules(GMP_PKG QUIET gmp)
endif()

if(GMP_PKG_FOUND)
  # GMP_PKG_INCLUDE_DIRS, GMP_PKG_LIBRARIES, GMP_PKG_LIBRARY_DIRS set automatically
  set(GMP_FOUND TRUE)
  set(GMP_INCLUDE_DIR "${GMP_PKG_INCLUDE_DIRS}")
  set(GMP_LIBRARY "${GMP_PKG_LIBRARIES}")
  set(GMP_VERSION "${GMP_PKG_VERSION}")

  # Create imported target if not already defined
  if(NOT TARGET gmp::gmp)
    add_library(gmp::gmp UNKNOWN IMPORTED)
    set_target_properties(gmp::gmp PROPERTIES
      IMPORTED_LOCATION "${GMP_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${GMP_INCLUDE_DIR}"
    )
  endif()

  message(STATUS "Found GMP via pkg-config:")
  message(STATUS "  Includes : ${GMP_INCLUDE_DIR}")
  message(STATUS "  Library  : ${GMP_LIBRARY}")
  message(STATUS "  Version  : ${GMP_VERSION}")
else()
  # Fallback manual search (for systems without pkg-config)
  find_path(GMP_INCLUDE_DIR NAMES gmp.h
    HINTS /usr/include /usr/local/include /opt/homebrew/include
  )
  find_library(GMP_LIBRARY NAMES gmp
    HINTS /usr/lib /usr/lib64 /usr/local/lib /usr/local/lib64 /opt/homebrew/lib
  )

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(GMP DEFAULT_MSG GMP_INCLUDE_DIR GMP_LIBRARY)
  if(GMP_FOUND)
    if(NOT TARGET gmp::gmp)
      add_library(gmp::gmp UNKNOWN IMPORTED)
      set_target_properties(gmp::gmp PROPERTIES
        IMPORTED_LOCATION "${GMP_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${GMP_INCLUDE_DIR}"
      )
    endif()
  endif()
endif()

