#!/bin/bash
# Upload with an Individual API key; no Team Issuer ID or Apple ID password is required.
set +x
set -euo pipefail
: "${ASC_PRIVATE_KEY:?Set ASC_PRIVATE_KEY}" "${ASC_KEY_ID:?Set ASC_KEY_ID}"
[[ "$ASC_KEY_ID" =~ ^[A-Z0-9]{10}$ ]] || exit 1

umask 077
upload_dir="$(mktemp -d "$RUNNER_TEMP/testflight-upload.XXXXXX")"
trap 'rm -rf "$upload_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
key_path="$upload_dir/AuthKey_$ASC_KEY_ID.p8"
printf '%s\n' "$ASC_PRIVATE_KEY" > "$key_path"
unset ASC_PRIVATE_KEY

# altool requires an issuer argument even for Individual keys. Match Fastlane's
# compatibility path: use the key ID as a placeholder and select the user subject.
xcrun altool --upload-package "$RUNNER_TEMP/testflight-export/CloudNow.ipa" \
  --api-key "$ASC_KEY_ID" --api-issuer "$ASC_KEY_ID" --api-key-subject user \
  --p8-file-path "$key_path"
printf 'Uploaded to App Store Connect. Apple processing and tester distribution follow separately.\n' >> "$GITHUB_STEP_SUMMARY"
