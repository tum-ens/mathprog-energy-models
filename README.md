# GNU MathProg models for energy system planning and operation

## The Models 

### DCFLOW

This linear programming model finds the minimum cost generation and network flow for a lossless network, while obeying linearised DC powerflow equations.

### DHMNL

This mixed-integer linear programming (MILP) model finds the maximum revenue topology and size of a district heating network for a given set of source and demand vertices. The model can decide which demands to connect and  consequently decide over the location and size of the built network.

### Equilibrium
### Intertemporal

This LP model finds the minimum cost investment plan for for a set of two power plant technologies over multiple decades, allowing investment decisions every five years. Old investments phase out of the power plant fleet after 

### N minus 1

This model finds the minimum cost network within a graph to redundantly connect a set of source to a set of demand points. "Redundantly" means that the resulting network is resilient against the failure of any single edge in the network, i.e. satisfying the ["N minus 1" criterion](https://emr.entsoe.eu/glossary/bin/view/ENTSO-E+Common+Glossary/N-1+Criterion).

### SOforSG

Storage Optimisation for Smart Grid. More explanation on [enerpymodelling.de](http://www.enerpymodelling.de/soforsg/).

### Startup and partial

This linear programming (LP) optimisation model finds a minimum-cost capacity expansion and unit commitment solution to a given demand  timeseries for a combination of a fluctuating feed-in (renewables) and a controllable technology (power plant). This model focuses on correctly depicting the trade-off in sizing the power plant with respect to its operation point, which can exhibit less efficiency than when operating at its nominal size.

## Installation

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
