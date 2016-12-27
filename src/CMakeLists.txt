cmake_minimum_required(VERSION 2.8.12)
project(libuv)

if(CMAKE_SYSTEM_NAME STREQUAL Linux)
  set (LIBUV_CMAKE_PLATFORM_UNIX 1)
  set (LIBUV_CMAKE_PLATFORM_LINUX 1)
endif()

if (CMAKE_SYSTEM_NAME STREQUAL Darwin)
  set (LIBUV_CMAKE_PLATFORM_UNIX 1)
  set (LIBUV_CMAKE_PLATFORM_DARWIN 1)
endif()

include_directories(
  libuv/include
  libuv/src
  )

add_compile_options(-pthread)
add_compile_options(-fPIC)
add_compile_options(-Wall)
add_compile_options(-Wextra)
add_compile_options(-Wno-unused-parameter)
add_compile_options(--std=gnu89)
add_compile_options(-pedantic)

add_definitions(-D_BUILDING_UV_SHARED=1)

if (LIBUV_CMAKE_PLATFORM_LINUX)
  add_compile_options(-Wstrict-aliasing)
  add_definitions(-D_GNU_SOURCE)
elseif (LIBUV_CMAKE_PLATFORM_DARWIN)
  add_compile_options(-arch i386)
  add_compile_options(-arch x86_64)
  add_definitions(-D_DARWIN_USE_64_BIT_INODE=1)
  add_definitions(-D_DARWIN_UNLIMITED_SELECT=1)
endif()

set(LIBUV_SOURCES
  libuv/src/fs-poll.c
  libuv/src/inet.c
  libuv/src/threadpool.c
  libuv/src/uv-common.c
  libuv/src/version.c
  libuv/src/unix/async.c
  libuv/src/unix/core.c
  libuv/src/unix/dl.c
  libuv/src/unix/fs.c
  libuv/src/unix/getaddrinfo.c
  libuv/src/unix/getnameinfo.c
  libuv/src/unix/loop.c
  libuv/src/unix/loop-watcher.c
  libuv/src/unix/pipe.c
  libuv/src/unix/poll.c
  libuv/src/unix/process.c
  libuv/src/unix/signal.c
  libuv/src/unix/stream.c
  libuv/src/unix/tcp.c
  libuv/src/unix/thread.c
  libuv/src/unix/timer.c
  libuv/src/unix/tty.c
  libuv/src/unix/udp.c
  libuv/src/unix/proctitle.c
  )

if (LIBUV_CMAKE_PLATFORM_LINUX)
  list (APPEND LIBUV_SOURCES
    libuv/src/unix/linux-core.c
    libuv/src/unix/linux-inotify.c
    libuv/src/unix/linux-syscalls.c
    )
elseif (LIBUV_CMAKE_PLATFORM_DARWIN)
  list (APPEND LIBUV_SOURCES
    libuv/src/unix/darwin.c
    libuv/src/unix/darwin-proctitle.c
    libuv/src/unix/kqueue.c
    libuv/src/unix/fsevents.c
    libuv/src/unix/pthread-barrier.c
    )
endif()

add_library(uv SHARED ${LIBUV_SOURCES})

# Prevent CMAKE from passing -Duv_EXPORTS when building.
set_target_properties(uv PROPERTIES DEFINE_SYMBOL "")

# Since this is a private version of the library, we don't need a soname.
set_target_properties(uv PROPERTIES NO_SONAME "True")

# Install to the root of the output folder.
install(TARGETS uv LIBRARY NAMELINK_SKIP DESTINATION .)
