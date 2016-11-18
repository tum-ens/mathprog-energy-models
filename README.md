# GNU MathProg models for energy system planning and operation


## Dependencies

The standalone solver `glpsol` from the GNU Linear Programming Toolkit (GLPK).

### Linux

Most distributions offer GLPK as a ready-made packages. If unsure, please consult your distribution's package index. 
On Debian, Debian-based (e.g. Ubuntu) distributions, this will work:

    sudo apt-get install glpk-utils
    
Note that package maintainers could potentially lag behind new versions up to several releases. If you want the most recent version, you might consider downloading the source code from the [project homepage](https://www.gnu.org/software/glpk/) and build the solver from source by following the instructions in the accompanying `INSTALL` file. Typically, this boils down to the following steps:

    $ tar -xzvf glpk-X-Y.tar.gz
    $ cd glpk-X-Y
    $ ./configure
    $ make
    $ make check
    $ sudo make install

To check whether (and where) the solver was installed, you can use:

    $ which glpsol
    /usr/bin/glpsol

### Windows

Binary builds for Windows are available through the [WinGLPK](https://sourceforge.net/projects/winglpk/). Just extract the contents of the ZIP file to a convenient location, e.g. `C:\GLPK`.
