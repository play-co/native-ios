native-ios
==========

The native iOS component for devkit HTML5 games.

## Updating timestep bindings

To generated files in js/, grab the _barista_ project [here][barista].

### Install Barista

In a sandbox directory,

```sh
git clone git@github.com:gameclosure/barista.git
cd barista
npm install
sudo npm link
```

### Create bindings

In tealeaf/core/templates/ observe all the .json file descriptors.
Change to the template directory and execute some commands:

```sh
barista -e spidermonkey -o ../../gen/ view.json
barista -e spidermonkey -o ../../gen/ image_map.json
barista -e spidermonkey -o ../../gen/ animate.json
```

You should have a set of `*.gen.h` and `*.gen.cpp` files in `tealeaf/gen`. Move
them into `js/include/js` for header files and `js/src` for source files.

[barista]: https://github.com/gameclosure/barista
