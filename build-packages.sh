#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$SCRIPT_ROOT/init-tools.sh"
"$SCRIPT_ROOT/Tools/msbuild.sh" /flp:v=diag "$SCRIPT_ROOT/pkg/Libuv/Libuv.builds" /p:PackageRID=ubuntu.14.04-x64
