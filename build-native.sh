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
CMAKE_BUILD_TYPE=Debug
BUILD_ARCH=x64
HOST_OS=Linux
FILE_EXTENSION=".so"

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
                    CMAKE_BUILD_TYPE=RelWithDebInfo
                ;;
                debug)
                    BUILD_TYPE=Debug
                    CMAKE_BUILD_TYPE=Debug
                ;;
                arm)
                    BUILD_ARCH=arm
                ;;
                *)
                    echo "Unknown Configuration '$1'"
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

BINARY_DIR="$BINARY_ROOT/$TARGET_OS.$BUILD_ARCH.$BUILD_TYPE"
OBJECT_DIR="$OBJECT_ROOT/$TARGET_OS.$BUILD_ARCH.$BUILD_TYPE"
UPDATE_SUBMODULE="git submodule update --init --recursive"

#get submodules if not present
if [ "$(ls -A $SUBMODULE_ROOT)" ]; then
     echo "Submodule already updated."
else
    echo "Updating submodule"
    echo $UPDATE_SUBMODULE
    eval $UPDATE_SUBMODULE
fi

# Probe for clang/clang++ unless CC and CXX are already set
CC=${CC:-}
CXX=${CXX:-}

if [ -z "$CC" ] || [ -z "$CXX" ]; then

    # First look for `clang-3.X` or `clang-3X`
    for minor_ver in {9..5}; do
        if [ $(command -v "clang-3.$minor_ver") ] && [ $(command -v "clang++-3.$minor_ver") ]; then
            CC=$(command -v "clang-3.$minor_ver")
            CXX=$(command -v "clang++-3.$minor_ver")

            break
        fi

        if [ $(command -v "clang-3$minor_ver") ] && [ $(command -v "clang++-3$minor_ver") ]; then
            CC=$(command -v "clang-3$minor_ver")
            CXX=$(command -v "clang++-3$minor_ver")

            break
        fi
    done

    # If CC and CXX are still unset, see if `clang` and `clang++` are present.
    if [ -z "$CC" ] && [ -z "$CXX" ] && [ $(command -v "clang") -eq 0 ] && [ $command -v "clang++" -eq 0 ]; then
        CC=$(command -v "clang")
        CXX=$(command -v "clang++")
    fi

    # If CC and CXX are still unset, we couldn't find clang or clang++, so we give up.
    if [ -z "$CC" ] || [ -z "$CXX" ]; then
        echo "Could not find clang or clang++, please install clang 3.5 or higher or set CC and CXX to the path to clang an clang++ respectively."
        exit 1
    fi
fi

export CC="$CC"
export CXX="$CXX"

mkdir -p $BINARY_DIR
mkdir -p $OBJECT_DIR

pushd "$OBJECT_DIR" > /dev/null 2>&1

# Since it's possible that cmake or make could fail for a "real" reason,
# let's disable set -e so we can popd out of the object directory if they fail.
set +e

echo "CC=$CC"
echo "CXX=$CXX"

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
(set x; make check -j)
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
find $BINARY_DIR/lib -type l -exec bash -c 'ln -f "$(readlink -m "$0")" "$0"' {} \;
find $BINARY_DIR/lib -regextype posix-extended -regex '^.*so' -exec mv '{}' $BINARY_DIR \;
set -e
echo "Build Succeeded."
