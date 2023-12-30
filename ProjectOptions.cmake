include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(conky_obsidian_tasks_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(conky_obsidian_tasks_setup_options)
  option(conky_obsidian_tasks_ENABLE_HARDENING "Enable hardening" ON)
  option(conky_obsidian_tasks_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    conky_obsidian_tasks_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    conky_obsidian_tasks_ENABLE_HARDENING
    OFF)

  conky_obsidian_tasks_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR conky_obsidian_tasks_PACKAGING_MAINTAINER_MODE)
    option(conky_obsidian_tasks_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(conky_obsidian_tasks_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(conky_obsidian_tasks_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(conky_obsidian_tasks_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(conky_obsidian_tasks_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(conky_obsidian_tasks_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(conky_obsidian_tasks_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(conky_obsidian_tasks_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(conky_obsidian_tasks_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(conky_obsidian_tasks_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(conky_obsidian_tasks_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(conky_obsidian_tasks_ENABLE_PCH "Enable precompiled headers" OFF)
    option(conky_obsidian_tasks_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(conky_obsidian_tasks_ENABLE_IPO "Enable IPO/LTO" ON)
    option(conky_obsidian_tasks_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(conky_obsidian_tasks_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(conky_obsidian_tasks_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(conky_obsidian_tasks_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(conky_obsidian_tasks_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(conky_obsidian_tasks_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(conky_obsidian_tasks_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(conky_obsidian_tasks_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(conky_obsidian_tasks_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(conky_obsidian_tasks_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(conky_obsidian_tasks_ENABLE_PCH "Enable precompiled headers" OFF)
    option(conky_obsidian_tasks_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      conky_obsidian_tasks_ENABLE_IPO
      conky_obsidian_tasks_WARNINGS_AS_ERRORS
      conky_obsidian_tasks_ENABLE_USER_LINKER
      conky_obsidian_tasks_ENABLE_SANITIZER_ADDRESS
      conky_obsidian_tasks_ENABLE_SANITIZER_LEAK
      conky_obsidian_tasks_ENABLE_SANITIZER_UNDEFINED
      conky_obsidian_tasks_ENABLE_SANITIZER_THREAD
      conky_obsidian_tasks_ENABLE_SANITIZER_MEMORY
      conky_obsidian_tasks_ENABLE_UNITY_BUILD
      conky_obsidian_tasks_ENABLE_CLANG_TIDY
      conky_obsidian_tasks_ENABLE_CPPCHECK
      conky_obsidian_tasks_ENABLE_COVERAGE
      conky_obsidian_tasks_ENABLE_PCH
      conky_obsidian_tasks_ENABLE_CACHE)
  endif()

  conky_obsidian_tasks_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (conky_obsidian_tasks_ENABLE_SANITIZER_ADDRESS OR conky_obsidian_tasks_ENABLE_SANITIZER_THREAD OR conky_obsidian_tasks_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(conky_obsidian_tasks_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(conky_obsidian_tasks_global_options)
  if(conky_obsidian_tasks_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    conky_obsidian_tasks_enable_ipo()
  endif()

  conky_obsidian_tasks_supports_sanitizers()

  if(conky_obsidian_tasks_ENABLE_HARDENING AND conky_obsidian_tasks_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR conky_obsidian_tasks_ENABLE_SANITIZER_UNDEFINED
       OR conky_obsidian_tasks_ENABLE_SANITIZER_ADDRESS
       OR conky_obsidian_tasks_ENABLE_SANITIZER_THREAD
       OR conky_obsidian_tasks_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${conky_obsidian_tasks_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${conky_obsidian_tasks_ENABLE_SANITIZER_UNDEFINED}")
    conky_obsidian_tasks_enable_hardening(conky_obsidian_tasks_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(conky_obsidian_tasks_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(conky_obsidian_tasks_warnings INTERFACE)
  add_library(conky_obsidian_tasks_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  conky_obsidian_tasks_set_project_warnings(
    conky_obsidian_tasks_warnings
    ${conky_obsidian_tasks_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(conky_obsidian_tasks_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(conky_obsidian_tasks_options)
  endif()

  include(cmake/Sanitizers.cmake)
  conky_obsidian_tasks_enable_sanitizers(
    conky_obsidian_tasks_options
    ${conky_obsidian_tasks_ENABLE_SANITIZER_ADDRESS}
    ${conky_obsidian_tasks_ENABLE_SANITIZER_LEAK}
    ${conky_obsidian_tasks_ENABLE_SANITIZER_UNDEFINED}
    ${conky_obsidian_tasks_ENABLE_SANITIZER_THREAD}
    ${conky_obsidian_tasks_ENABLE_SANITIZER_MEMORY})

  set_target_properties(conky_obsidian_tasks_options PROPERTIES UNITY_BUILD ${conky_obsidian_tasks_ENABLE_UNITY_BUILD})

  if(conky_obsidian_tasks_ENABLE_PCH)
    target_precompile_headers(
      conky_obsidian_tasks_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(conky_obsidian_tasks_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    conky_obsidian_tasks_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(conky_obsidian_tasks_ENABLE_CLANG_TIDY)
    conky_obsidian_tasks_enable_clang_tidy(conky_obsidian_tasks_options ${conky_obsidian_tasks_WARNINGS_AS_ERRORS})
  endif()

  if(conky_obsidian_tasks_ENABLE_CPPCHECK)
    conky_obsidian_tasks_enable_cppcheck(${conky_obsidian_tasks_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(conky_obsidian_tasks_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    conky_obsidian_tasks_enable_coverage(conky_obsidian_tasks_options)
  endif()

  if(conky_obsidian_tasks_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(conky_obsidian_tasks_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(conky_obsidian_tasks_ENABLE_HARDENING AND NOT conky_obsidian_tasks_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR conky_obsidian_tasks_ENABLE_SANITIZER_UNDEFINED
       OR conky_obsidian_tasks_ENABLE_SANITIZER_ADDRESS
       OR conky_obsidian_tasks_ENABLE_SANITIZER_THREAD
       OR conky_obsidian_tasks_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    conky_obsidian_tasks_enable_hardening(conky_obsidian_tasks_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
