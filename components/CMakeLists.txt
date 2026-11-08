# CMake build system for CMatrix

cmake_minimum_required(VERSION 4.4.2)

project(screen LANGUAGES C)
set(VERSION "3.1")

include(GNUInstallDirs)

# These are relative to CMAKE_INSTALL_PREFIX
# which by default is "/usr/local"
set(CONSOLE_FONTS_DIRS "share/consolefonts" "lib/kbd/consolefonts")
set(X_FONTS_DIRS "lib/X11/fonts/misc" "X11R6/lib/X11/fonts/misc" "share/fonts/X11/misc")

set(MKFONTDIR "/usr/bin/mkfontdir")

# Check for CJK font availability at build configuration time
find_program(FC_LIST fc-list)
if(FC_LIST)
    execute_process(
        COMMAND ${FC_LIST} ":family=Noto Sans CJK JP"
        OUTPUT_VARIABLE CJK_FONT_CHECK
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT CJK_FONT_CHECK)
        message(WARNING "Noto Sans CJK was not detected. Kanji characters will not render properly without the CJK font installed.")
    endif()
endif()

# configure_file(config.h.in config.h)

add_definitions(-DVERSION="${VERSION}")
add_definitions(-DUSE_TIOCSTI)

include(CheckIncludeFiles)
check_include_files("sys/ioctl.h" HAVE_SYS_IOCTL_H)
if	(HAVE_SYS_IOCTL_H)
	add_definitions(-DHAVE_SYS_IOCTL_H)
endif	()
check_include_files("unistd.h" HAVE_UNISTD_H)
if	(HAVE_UNISTD_H)
	add_definitions(-DHAVE_UNISTD_H)
endif	()
check_include_files("termios.h" HAVE_TERMIOS_H)
if	(HAVE_TERMIOS_H)
	add_definitions(-DHAVE_TERMIOS_H)
endif	()
check_include_files("getopt.h" HAVE_GETOPT_H)
if	(HAVE_GETOPT_H)
	add_definitions(-DHAVE_GETOPT_H)
endif	()

Set(CURSES_NEED_NCURSES TRUE)
Set(CURSES_NEED_WIDE TRUE)
find_package(Curses)
include_directories(${CURSES_INCLUDE_DIR})
add_definitions(-DHAVE_NCURSES_H)

include(CheckSymbolExists)
list(APPEND CMAKE_REQUIRED_LIBRARIES ncurses)
check_symbol_exists(use_default_colors "ncurses.h" HAVE_USE_DEFAULT_COLORS)
if (HAVE_USE_DEFAULT_COLORS)
    add_definitions(-DHAVE_USE_DEFAULT_COLORS)
endif()

add_executable(cmatrix cmatrix.c)

set_target_properties(cmatrix PROPERTIES OUTPUT_NAME "screen")

target_link_libraries(cmatrix ${CURSES_LIBRARIES})

install(TARGETS cmatrix DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES screen.1 DESTINATION ${CMAKE_INSTALL_MANDIR}/man1)
