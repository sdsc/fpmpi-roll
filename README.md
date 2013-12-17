# SDSC "fpmpi" roll

## Overview

This roll bundles the FPMPI MPI profiling library.

For more information about the various packages included in the fpmpi roll please visit their official web pages:

- <a href="http://www.mcs.anl.gov/research/projects/fpmpi/WWW/"
target="_blank">FPMPI-2</a> is a simple MPI profiling library.


## Requirements

To build/install this roll you must have root access to a Rocks development
machine (e.g., a frontend or development appliance).

If your Rocks development machine does *not* have Internet access you must
download the appropriate fpmpi source file(s) using a machine that does
have Internet access and copy them into the `src/fpmpi` directory on your
Rocks development machine.


## Dependencies

Unknown at this time.


## Building

To build the fpmpi-roll, execute these instructions on a Rocks development
machine (e.g., a frontend or development appliance):

```shell
% make default 2>&1 | tee build.log
% grep "RPM build error" build.log
```

If nothing is returned from the grep command then the roll should have been
created as... `fpmpi-*.iso`. If you built the roll on a Rocks frontend then
proceed to the installation step. If you built the roll on a Rocks development
appliance you need to copy the roll to your Rocks frontend before continuing
with installation.

This roll source supports building with different compilers and for different
network fabrics and mpi flavors.  By default, it builds using the gnu compilers
for openmpi ethernet.  To build for a different configuration, use the
`ROLLCOMPILER`, `ROLLMPI` and `ROLLNETWORK` make variables, e.g.,

```shell
make ROLLCOMPILER=intel ROLLMPI=mpich2 ROLLNETWORK=mx 
```

The build process currently supports one or more of the values "intel", "pgi",
and "gnu" for the `ROLLCOMPILER` variable, defaulting to "gnu".  It supports
`ROLLMPI` values "openmpi", "mpich2", and "mvapich2", defaulting to "openmpi".
It uses any `ROLLNETWORK` variable value(s) to load appropriate mpi modules,
assuming that there are modules named `$(ROLLMPI)_$(ROLLNETWORK)` available
(e.g., `openmpi_ib`, `mpich2_mx`, etc.).

If the `ROLLCOMPILER`, `ROLLNETWORK` and/or `ROLLMPI` variables are specified,
their values are incorporated into the names of the produced roll and rpms, e.g.,

```shell
make ROLLCOMPILER=intel ROLLMPI=mvapich2 ROLLNETWORK=ib
```
produces a roll with a name that begins "`fpmpi_intel_mvapich2_ib`"; it
contains and installs similarly-named rpms.

For gnu compilers, the roll also supports a `ROLLOPTS` make variable value of
'avx', indicating that the target architecture supports AVX instructions.


## Installation

To install, execute these instructions on a Rocks frontend:

```shell
% rocks add roll *.iso
% rocks enable roll fpmpi
% cd /export/rocks/install
% rocks create distro
% rocks run roll fpmpi | bash
```

In addition to the software itself, the roll installs fpmpi environment
module files in:

```shell
/opt/modulefiles/applications/.(compiler)/fpmpi.
```


## Testing

The fpmpi-roll includes a test script which can be run to verify proper
installation of the fpmpi-roll documentation, binaries and module files. To
run the test scripts execute the following command(s):

```shell
% /root/rolltests/fpmpi.t 
ok 1 - fpmpi is installed
ok 2 - fpmpi test run
ok 3 - fpmpi module installed
ok 4 - fpmpi version module installed
ok 5 - fpmpi version module link created
1..5
```
