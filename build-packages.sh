#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PackageRID=ubuntu.14.04-x64

SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$SCRIPT_ROOT/init-tools.sh"
if [ ! $# -eq 0 ]; then
    PackageRID=$1
fi
"$SCRIPT_ROOT/Tools/msbuild.sh" /flp:v=diag "$SCRIPT_ROOT/pkg/Libuv/Libuv.builds" /p:PackageRID=$PackageRID
