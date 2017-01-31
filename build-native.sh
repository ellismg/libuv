#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_ROOT=$(cd "$(dirname "$0")"; pwd -P)
REPO_ROOT="$SCRIPT_ROOT"
SOURCE_ROOT="$REPO_ROOT/src"
BINARY_ROOT="$REPO_ROOT/bin"
OBJECT_ROOT="$REPO_ROOT/obj"
SUBMODULE_ROOT="$REPO_ROOT/src/libuv"

BUILD_TYPE=Debug
TARGET_ARCH=x64
HOST_OS=Linux
FILE_EXTENSION=".so"
#with the given install script this works on macs, need to override glibtoolize
export LIBTOOLIZE="libtoolize"

case $(uname -s) in
    Darwin)
        HOST_OS="OSX"
        FILE_EXTENSION=".dylib"
        ;;
    Linux)
        HOST_OS="Linux"
        FILE_EXTENSION=".so"
        ;;
    *)
        echo "Unknown OS: '$(uname -s)'"
        exit 1
        ;;
esac

TARGET_OS="$HOST_OS"

while :; do
    if [ $# -le 0 ]; then
        break
    fi

    case $(echo $1 | awk '{print tolower($0)}') in
        --configuration)
            shift
            case $(echo $1 | awk '{print tolower($0)}') in
                release)
                    BUILD_TYPE=Release
                ;;
                debug)
                    BUILD_TYPE=Debug
                ;;
                *)
                    echo "Unknown Configuration '$1'"
                    exit 1
                ;;
            esac
            ;;
        --platform)
            shift
            case $(echo $1 | awk '{print tolower($0)}') in
                x64)
                    TARGET_ARCH=x64
                ;;
                arm)
                    TARGET_ARCH=arm
                ;;
                *)
                    echo "Unknown Platform '$1'"
                    exit 1
                ;;
            esac
            ;;
        *)
            echo "Unknown Argument '$1'"
            exit 1
            ;;
    esac

    shift
done

BINARY_DIR="$BINARY_ROOT/$TARGET_OS.$TARGET_ARCH.$BUILD_TYPE"
OBJECT_DIR="$OBJECT_ROOT/$TARGET_OS.$TARGET_ARCH.$BUILD_TYPE"

git submodule init
git submodule update

mkdir -p $BINARY_DIR
mkdir -p $OBJECT_DIR

pushd "$OBJECT_DIR" > /dev/null 2>&1

# Since it's possible that cmake or make could fail for a "real" reason,
# let's disable set -e so we can popd out of the object directory if they fail.
set +e

#Call libuv build commands
echo "Commencing build of native compenents"
echo .
echo $SUBMODULE_ROOT
pushd $SUBMODULE_ROOT
echo "Building with autotools"
(set -x; sh autogen.sh)
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed."
    popd > /dev/null 2>&1
    exit 1
fi
(sh configure --prefix=$BINARY_DIR)
(set x; make -j)
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed."
    popd > /dev/null 2>&1
    exit 1
fi
(set x; make install -j)
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed."
    popd > /dev/null 2>&1
    exit 1
fi
popd
pushd $BINARY_DIR/lib
for n in *; 
do
   echo "$n"
   if [[ -f "$n" ]]; then
   if [[ ! -z $(readlink "$n") ]]; then
     LINKVALUE=$(readlink "$n")
     echo ln -f "$LINKVALUE" "$n" 
     ln -f "$LINKVALUE" "$n"
     if [[ $n == *$FILE_EXTENSION* ]]; then
       mv $n $BINARY_DIR
     fi
   fi
   fi
done
popd
set -e
echo "Build Succeeded."
