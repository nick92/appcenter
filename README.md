# AppHive

**This application is currently in beta and so contains many bugs**

A universal application manager for *buntu systems, supporting deb and snap packages. Based on [elementary AppCenter](https://github.com/elementary/appcenter)

![Screenshot](data/screenshot.png?raw=true)

## Packages

Currently supports Deb and Snap packages

## Building, Testing, and Installation

You'll need the following dependencies:
* cmake
* [cmake-elementary](https://github.com/elementary/cmake-modules)
* intltool
* libappstream-dev (>= 0.10)
* [libsnapd-glib](https://github.com/snapcore/snapd-glib) (>=1.19) 
* libgee-0.8-dev
* libgranite-dev (>=0.5)
* libgtk-3-dev
* libjson-glib-dev
* libpackagekit-glib2-dev
* libsoup2.4-dev
* libunity-dev
* libxml2-dev
* libxml2-utils
* valac (>= 0.26)

It's recommended to create a clean build environment

    mkdir build && cd build

Run `cmake` to configure the build environment and then `make all test` to build and run automated tests

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make all test

To install, use `make install`, then execute with `io.elementary.appcenter`

    sudo make install
    io.elementary.appcenter
