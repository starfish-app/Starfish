<img align="left" width="64" height="64" src="https://raw.githubusercontent.com/starfish-app/starfish/main/data/icons/64.png">
<h1>Starfish</h1>

A [Gemini](https://gemini.circumlunar.space/) browser made for [elementary OS](https://elementary.io/).

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](COPYING)

|![Default style Screenshot](https://raw.githubusercontent.com/starfish-app/starfish/main/data/default-style.png)|![Dark style Screenshot](https://raw.githubusercontent.com/starfish-app/starfish/main/data/dark-style.png)|
|----------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| Starfish browser rendering an introduction to Gemini page | Starfish client with the dark theme rendering its own project page on Gemini |

## About

Starfish is a graphical client for the Gemini protocol built with GTK and Vala. The main goal of the project is to provide a native elementary OS application for reading Gemini sites, that will make the protocol more accessible to users. Read more on the project's Gemini page: [gemini://josipantolis.from.hr/starfish/](gemini://josipantolis.from.hr/starfish/).

### Status

Starfish is in active development. It currently supports core of the Gemini specification, including gemtext rendering, and can be used to view images and download other file types. There are still some missing features, such as client certificates, or support for subscribing to gemlogs. There are also UI features that could use improvements, such as adding search for gemtext pages, or improving the image viewing.

## Build

Starfish is built for elementary OS 6. All prerequisites can be met by installing `elementary-sdk` and `libgnutls28-dev`:

```sh
sudo apt install elementary-sdk libgnutls28-dev
```

To build and install the app execute (from project's root directory):

```sh
meson build --prefix=/usr
cd build
ninja
sudo ninja install
```

### Test

After performing meson build you can run tests from inside `build` directory with:

```sh
meson test
```

### Translate

After adding user facing strings, remember to wrap them `_("like so")`, from inside the `build` directory execute:

```sh
ninja hr.from.josipantolis.starfish-pot
ninja hr.from.josipantolis.starfish-update-po
```

## Package

Starfish is packaged as a Flatpak. You can build and install it locally with:

```sh
flatpak-builder build hr.from.josipantolis.starfish.yml --user --install --force-clean
```

## License

[GNU GPLv3](COPYING)

Copyright © 2021 Josip Antoliš, josip.antolis@protonmail.com.

