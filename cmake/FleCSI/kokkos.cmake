function(_flecsi_check_kokkos_compiler)
  if(Kokkos_ENABLE_CUDA AND CMAKE_BUILD_TYPE STREQUAL "Debug" AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND
     CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 13.0.1 AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 20.1.0)
     message(WARNING "Disabling GPU debuginfo for Clang > 13.0.1, < 20.1.0 due to "
                     "https://github.com/llvm/llvm-project/issues/58491")
  endif()
endfunction()

# Kokkos built with Kokkos_ENABLE_COMPILE_AS_CMAKE_LANGUAGE compiles its sources
# with CMake's CUDA or HIP language instead of CXX, and so must every source that
# includes Kokkos, which is every source that includes FleCSI.
macro(_flecsi_enable_kokkos_language)
  if(Kokkos_COMPILE_LANGUAGE AND NOT Kokkos_COMPILE_LANGUAGE STREQUAL CXX)
    enable_language(${Kokkos_COMPILE_LANGUAGE})
    set(CMAKE_${Kokkos_COMPILE_LANGUAGE}_ARCHITECTURES
      ${Kokkos_${Kokkos_COMPILE_LANGUAGE}_ARCHITECTURES})
  endif()
endmacro()

# Compile the C++ sources of the given targets with the Kokkos compile language,
# for the GPU architectures of Kokkos. Call it from the directory that defines
# the targets.
function(flecsi_kokkos_language)
  if(Kokkos_COMPILE_LANGUAGE AND NOT Kokkos_COMPILE_LANGUAGE STREQUAL CXX)
    foreach(target IN LISTS ARGN)
      get_target_property(sources ${target} SOURCES)
      list(FILTER sources INCLUDE REGEX "\\.(cc|cpp|cxx)$")
      if(sources)
        set_source_files_properties(${sources} PROPERTIES
          LANGUAGE ${Kokkos_COMPILE_LANGUAGE})
      endif()
      set_target_properties(${target} PROPERTIES
        ${Kokkos_COMPILE_LANGUAGE}_ARCHITECTURES
        "${Kokkos_${Kokkos_COMPILE_LANGUAGE}_ARCHITECTURES}")
    endforeach()
  endif()
endfunction()

macro(flecsi_enable_kokkos target)
  find_package(Kokkos COMPONENTS separable_compilation REQUIRED)
  _flecsi_enable_kokkos_language()
  target_link_libraries(${target} PUBLIC Kokkos::kokkos)

  if(Kokkos_ENABLE_CUDA)
    _flecsi_check_kokkos_compiler()
    target_compile_options(${target} PUBLIC
      $<$<AND:$<CXX_COMPILER_ID:Clang>,$<CONFIG:Debug>,$<VERSION_GREATER:$<CXX_COMPILER_VERSION>,13.0.1>,$<VERSION_LESS:$<CXX_COMPILER_VERSION>,20.1.0>>:-Xarch_device -g0>)
  endif()
endmacro()
