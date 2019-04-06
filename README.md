# AppHive

A universal application manager for *buntu systems, supporting deb and snap packages. Based on [elementary AppCenter](https://github.com/elementary/appcenter)

![Screenshot](data/screenshot.png?raw=true)

## Packages

Currently supports Debian and Snap packages

## Building, Testing, and Installation

You'll need the following dependencies:
* meson
* gettext
* libappstream-dev (>= 0.10)
* [libsnapd-glib-dev](https://github.com/snapcore/snapd-glib) (>=1.19) 
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

    mkdir build && meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute

    sudo ninja install
    apphive	