#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PACKAGE_RID=ubuntu.14.04-x64
BUILD_TYPE=Debug

SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
        --runtime-id)
            shift
            PACKAGE_RID=$(echo $1 | awk '{print tolower($0)}')
            ;;
        *)
            echo "Unknown Argument '$1'"
            exit 1
            ;;
    esac

    shift
done

"$SCRIPT_ROOT/init-tools.sh"
"$SCRIPT_ROOT/Tools/msbuild.sh" /flp:v=diag "$SCRIPT_ROOT/pkg/Libuv/Libuv.builds" /p:PackageRID=$PACKAGE_RID /p:ConfigurationGroup=$BUILD_TYPE
