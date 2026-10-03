#!/bin/bash
# Build, test and launch only with the requested native toolchain.
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
xcode_version="$(xcodebuild -version | python3 -c 'import sys; print(sys.stdin.read().splitlines()[0].split()[1])')"
if ! python3 - "$xcode_version" <<'PY'
import sys
parts=tuple(int(part) for part in sys.argv[1].split('.'))
raise SystemExit(0 if parts >= (26, 3) else 1)
PY
then
  echo "PENDING: Xcode 26.3 or newer required. Selected Xcode is $xcode_version. No iOS build attempted."
  exit 2
fi
sdk_version="$(xcrun --sdk iphonesimulator --show-sdk-version)"
case "$sdk_version" in
  26.*) ;;
  *) echo "PENDING: iOS 26 SDK required; found $sdk_version."; exit 2 ;;
esac
# Pass an explicit simulator UUID as the first argument, or select an available iOS 26 iPhone.
simulator_id="${1:-}"
if [ -z "$simulator_id" ]; then
  simulator_id="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; data=json.load(sys.stdin); preferred="iOS-"+sys.argv[1].replace(".","-"); devices=[(runtime,d) for runtime,ds in data["devices"].items() if "iOS-26-" in runtime for d in ds if "iPhone" in d["name"] and d.get("isAvailable")]; devices.sort(key=lambda pair:(preferred not in pair[0],pair[1]["state"]!="Booted")); print(devices[0][1]["udid"] if devices else "")' "$sdk_version")"
fi
if [ -z "$simulator_id" ]; then
  echo "PENDING: Install an iOS 26 iPhone simulator runtime in Xcode Settings > Components."
  exit 2
fi
xcrun simctl bootstatus "$simulator_id" -b
xcodebuild -project "$project_dir/BigHand.xcodeproj" -scheme BigHand -configuration Debug \
  -destination "platform=iOS Simulator,id=$simulator_id" -derivedDataPath "$project_dir/DerivedData" \
  CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO test
xcrun simctl install "$simulator_id" "$project_dir/DerivedData/Build/Products/Debug-iphonesimulator/BigHand.app"
xcrun simctl launch "$simulator_id" com.bighand.game
echo "PASS: iOS build, XCTest and simulator process launch. Playtest controls and game feel on an iPhone next."
