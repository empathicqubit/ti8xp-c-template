# ti8xp-c-template

A debuggable project for TI8x calculators, such as TI 83/84 Plus and maybe others.
It lets you debug directly on the calculator via a USB or serial cable.
It is currently quite slow, and the lines are offset a bit wrong.


## Building
If you have all the dependencies, then all you need to do is run these commands:

```
# Run the program on the calculator and wait for a connection from z88dk-gdb.
make start
# Run the bridge program, which takes the output from the calculator and sends
# it to a TCP port using socat.
TIBRIDGE_PORT=8998 make tibridge
# Connect to the bridge program
z88dk-gdb -x ./build/program.map -h 127.0.0.1 -p 8998
```

In vscode it is even easier. Run the "Start program" task to start it on the 
calculator, then run the "TI Debug Bridge" to start the bridge. Finally, go
to the debugger action tab and launch the "Attach" configuration.

## Dependencies

Look at the Dockerfile to see what dependencies are there, you will need:

* TILP
* ticables-gdb-bridge (currently included in the project)
* z88dk 2.2

In order to build ticables-gdb-bridge successfully, you will need

* ticables2
* ticalcs2
* tifiles2
* glib-2.0
* readline

and their dev packages.

## Credits

This project is based on the [TI C project template](https://github.com/empathicqubit/ti8xp-c-template)
