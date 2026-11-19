#!/usr/bin/env bash
set -euo pipefail

# Path to the wfn executable; override with the WFN_PATH env var
WFN="${WFN_PATH:-wfn}"

# Check wfn exists
if ! command -v "$WFN" >/dev/null 2>&1; then
  echo "Error: '$WFN' WebFunction CLI tool was not found in your PATH." >&2
  echo "You can specify its location using the WFN_PATH environment variable, e.g.:" >&2
  echo "  WFN_PATH=/path/to/wfn $0" >&2
  echo "If you don't have the tool, get/build it from https://github.com/webfunction-protocol/webfunction-cli" >&2
  exit 1
fi

# Check wfn is new enough to report its version (older builds have no --version)
if ! WFN_VERSION="$("$WFN" --version 2>/dev/null)" || [ -z "$WFN_VERSION" ]; then
  echo "Error: '$WFN' is too old - it does not support --version (and --hashfile)." >&2
  echo "Get/build a newer one from https://github.com/webfunction-protocol/webfunction-cli" >&2
  exit 1
fi

# Set the copyright year in the license to the current year
sed "s/^Copyright (c) [0-9]\{4\}/Copyright (c) $(date +%Y)/" LICENSE.txt > LICENSE.txt.tmp
mv LICENSE.txt.tmp LICENSE.txt

# Each client's package hash is written here by wfn, then collected into buildinfo.json
HASH_DIR="$(mktemp -d)"
trap 'rm -rf "$HASH_DIR"' EXIT

# Generate code for clients (each API is its own C# namespace)
"$WFN" codegen --target csharp --url https://api.reservepay.com/merchants -o ./src/Reservepay/Merchant.cs --namespace Reservepay.Merchant --hashfile "$HASH_DIR/merchants"
"$WFN" codegen --target csharp --url https://api.reservepay.com/terminals -o ./src/Reservepay/Terminal.cs --namespace Reservepay.Terminal --hashfile "$HASH_DIR/terminals"
"$WFN" codegen --target csharp --url https://api.reservepay.com/sdk -o ./src/Reservepay/SDK.cs --namespace Reservepay.SDK --hashfile "$HASH_DIR/sdk"

# Record what the clients were generated with and from, in buildinfo.json
MERCHANTS_HASH="$(cat "$HASH_DIR/merchants")"
TERMINALS_HASH="$(cat "$HASH_DIR/terminals")"
SDK_HASH="$(cat "$HASH_DIR/sdk")"
BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > buildinfo.json.tmp <<EOF
{
  "wfnVersion": "$WFN_VERSION",
  "packageHashes": {
    "merchants": "$MERCHANTS_HASH",
    "terminals": "$TERMINALS_HASH",
    "sdk": "$SDK_HASH"
  },
  "buildTime": "$BUILD_TIME"
}
EOF
mv buildinfo.json.tmp buildinfo.json

# Check the generated clients compile (needs dotnet). To build against a local webfunction-csharp checkout, set
# WEBFUNCTION_PROJECT to the path of its WebFunction.csproj
if command -v dotnet >/dev/null 2>&1; then
  dotnet build ./src/Reservepay/Reservepay.csproj ${WEBFUNCTION_PROJECT:+-p:WebFunctionProject="$WEBFUNCTION_PROJECT"}
  echo "Clients generated and 'dotnet build' passed"
else
  echo "Install the .NET SDK and run 'dotnet build' to check the generated clients compile"
fi
