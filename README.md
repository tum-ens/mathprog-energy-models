# MathProg models for energy system planning and operation

This repository contains a collection of mathematical optimisation models that have been developed for educational purposes for several lectures. They are collected here for easier maintenance and better visibility of what has been implemented already.

The common theme among these models is **capacity expansion**, **power flow** and **plant scheduling** for **minimum total system cost** (or - in the case of DHMNL - maximum revenue), each model stressing another aspect of common tasks in modelling of energy systems.

## Models

### DCFLOW

This linear programming (LP) model finds the minimum cost generation and network flow for a lossless electricity network, while obeying **linearised DC powerflow** equations (consult a textbook, or [The DC Power Flow Equations](http://home.eng.iastate.edu/~jdm/ee553/DCPowerFlowEquations.pdf) for a quick primer). It is present in two semantically identical, but mathematically different formulations: `dcflow_arc` uses directed arcs (two per edge) and contains only positive flow variables, the direction directly corresponding to that of its containing arc. `dcflow_edge` only contains one edge between each pair of connected vertices, and an unconstrained flow variable instead, encoding direction in its sign. While the edge formulation uses less variables and thus is more efficient for only this problem, the arc formulation can make it easier to add further variables and constraints that interact with the modelled power flow.

### DHMNL

This mixed-integer linear programming (MILP) model finds the **maximum revenue topology and size** of a district heating (DH) network for a given set of source and demand vertices. The model **can decide which demands to connect** and consequently plans the location and size of the built network. Different from most other models here, this implies that the system under design does not have to satisfy a demand, but can select only a (possibly empty) subset of profitable customers.

### Equilibrium

This linear programming (LP) model finds the **maximum welfare** solution for a given set of *a) a discretised production cost curve* (i.e. a **merit order** curve) and *b) a discretised utility function* of customers (i.e. a **price-demand** curve). It thus finds the [economic equilibrium](https://en.wikipedia.org/wiki/Economic_equilibrium) of the market situation encoded by its inputs.

### Intertemporal

This linear programming (LP) model finds the minimum cost **investment plan** for for a set of two power plant technologies over multiple decades, allowing investment decisions every five years. Old investments phase out of the power plant fleet after the parameterised **lifetime** of each investment is over.

### N minus 1

This mixed-integer linear programming (MILP) model finds the minimum cost network within a graph to **redundantly connect a set of source to a set of demand points**. "Redundantly" means that the resulting network is resilient against the failure of any single edge in the network, i.e. satisfying the [N-1 Criterion](https://www.entsoe.eu/fileadmin/user_upload/_library/publications/entsoe/Operation_Handbook/glossary_v22.pdf#page=9) common in electric grid design.

### SOforSG

This linear programming (LP) model is an abbreviation of *Storage Optimisation for Smart Grid*. This model determines optimal **size and operation** of a hypothetical lossless **storage technology** for electric energy. A given electricity demand must be satisfied from *either* a cost-free (renewable) energy supply with intermittent characteristic *or* from purchase of electricity from the grid for a time-dependent price. Surplus renewable energy can be sold either at generation time, or stored to yield a higher revenue later. This model is the core idea behind [urbs](https://github.com/tum-ens/urbs), which generalises the size and operation optimisation to an arbitrary number of energy conversion, transmission and storage processes (at aan rbitrary number of conceptual nodes, called *sites*). The central idea, the energy balance constraint, storage state equation and a cost minimisation objective function, are all present here.

### Startup and partial

This linear programming (LP) optimisation model finds a **minimum-cost capacity expansion and unit commitment** solution to a given demand  timeseries for a combination of a fluctuating feed-in (renewables) and a controllable technology (power plant). This model focuses on correctly depicting the trade-off in sizing the power plant with respect to its operation point, which can exhibit less efficiency than when operating below its nominal size. These properties are approximated by a formulation that combines **startup costs** with a linearily increasing or decreasing **conversion efficiency**, depending on the **operation point**.

### Unit commitment

This mixed-integer linear programming (MILP) model finds a cost-minimal power plant **operation schedule** for a given demand timeseries. Modelled power plant attributes are minimum and maximum output capacity, startup and shutdown costs, operational fixed (when switched on) and variable (by power production) costs. This formulation is computationally more complex than the one used in model *Startup and partial*, but more accurate in that it depicts the discrete nature of the on-off decision. Also, it allows for more extensions similar to state-of-the-art unit commitment models, e.g.: minimum runtimes, minimum cooldown times, hot or warm start capabilities.


## Installation

All models require the standalone solver `glpsol` from the GNU Linear Programming Toolkit (GLPK).

### Web

For short experiments, there is [GLPK Online](https://cocoto.github.io/glpk-online/), a Javascript port of GLPK and MathProg. Just copy & paste the model code into the text box, press *Solve*, inspect model ouptut in tab *Output*.

### Windows

Binary builds for Windows are available through the [WinGLPK](https://sourceforge.net/projects/winglpk/). Just extract the contents of the ZIP file to a convenient location, e.g. `C:\GLPK`. You then can either call a model using:

    C:\GLPK\bin\glpsol.exe -m model.mod
    
However, it is recommended to add the subdirectory `w64`, which contains the file `glpsol.exe`, to the system path ([how](http://geekswithblogs.net/renso/archive/2009/10/21/how-to-set-the-windows-path-in-windows-7.aspx)), so that the command `glpsol` is available on the command prompt from any directory directly:

    glpsol -m model.mod

### Linux packages

Most distributions offer GLPK as a ready-made packages. If unsure, please consult your distribution's package index. On Debian or Debian-based (e.g. Ubuntu) distributions, executing the following command on the terminal (excluding the `$ `):

    $ sudo apt-get install glpk-utils
    
Note that package maintainers could potentially lag behind new versions up to several releases. To check which version you have installed, you can use:

    $ glpsol --version

### Building from source

If you want the most recent version, you might consider downloading the source code from the [project homepage](https://www.gnu.org/software/glpk/) and build the solver from source by following the instructions in the accompanying `INSTALL` file. Typically, this boils down to the following steps, where `X-Y` must be replaced by the version number, e.g. `4-60`:

    $ tar -xzvf glpk-X-Y.tar.gz
    $ cd glpk-X-Y
    $ ./configure
    $ make
    $ make check
    $ sudo make install

To check whether (and where) the solver was installed, you can use:

    $ which glpsol
    /usr/bin/glpsol


## Copyright

Each model has its own author and license statement in the file header. Most models so far have the Creative Commons Public Domain Dedication, short [CC0](https://creativecommons.org/publicdomain/zero/1.0). In other words, *you can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.* Some minor conditions still apply, most notably: *When using or citing the work, you should not imply endorsement by the author or the affirmer.* But that's about it. But when in doubt, read the [full license text](https://creativecommons.org/publicdomain/zero/1.0/legalcode).
