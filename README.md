# libuv

This repository contains the version of [libuv](https://github.com/libuv/libuv)
used by the .NET Core project.

The actual libuv sources are present as a submodule in `src/libuv`. The rest of
this repository is dedicated to .NET Core specific build logic used to ingest
libuv into .NET Core.

# Build Dependencies

To install build dependencies on Ubuntu, run

```
sudo apt-get install build-essential libtool automake autoconf
```

or alternatively 

```
sudo apt-get install autotools-dev
```

On Windows, install Python 2.7 or higher as dependency and msbuild.

On MacOS, run cltools.sh to install autotools.
