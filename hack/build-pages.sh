#!/usr/bin/env bash

set -euo pipefail

output_dir="${1:-public}"
repository_version="${MAILAPI_REPOSITORY_VERSION:-development}"

if [[ "$output_dir" == /* || "$output_dir" == "." || "$output_dir" == ".." || "$output_dir" == *".."* ]]; then
  echo "Output directory must be a safe relative path." >&2
  exit 1
fi

if [[ ! "$repository_version" =~ ^[0-9A-Za-z._+-]+$ ]]; then
  echo "Repository version must contain only letters, numbers, dots, underscores, plus signs, or hyphens." >&2
  exit 1
fi

rm -rf -- "$output_dir"
mkdir -p "$output_dir/examples" "$output_dir/compatibility/clouds" "$output_dir/compatibility/frameworks" "$output_dir/compatibility/languages" "$output_dir/compatibility/protocols"
mkdir -p "$output_dir/api/swagger-ui"

cp site/_config.yml "$output_dir/_config.yml"
printf '\nrepository_version: "%s"\n' "$repository_version" >> "$output_dir/_config.yml"
cp site/index.md "$output_dir/index.md"
cp site/api/index.html "$output_dir/api/index.html"
cp site/api/swagger-ui/LICENSE "$output_dir/api/swagger-ui/LICENSE"
cp site/api/swagger-ui/NOTICE "$output_dir/api/swagger-ui/NOTICE"
cp site/api/swagger-ui/swagger-ui.css "$output_dir/api/swagger-ui/swagger-ui.css"
cp site/api/swagger-ui/swagger-ui-bundle.js "$output_dir/api/swagger-ui/swagger-ui-bundle.js"
cp site/api/swagger-ui/swagger-ui-bundle.js.LICENSE.txt "$output_dir/api/swagger-ui/swagger-ui-bundle.js.LICENSE.txt"
cp site/api/swagger-ui/swagger-ui-standalone-preset.js "$output_dir/api/swagger-ui/swagger-ui-standalone-preset.js"
cp site/api/swagger-ui/swagger-ui-standalone-preset.js.LICENSE.txt "$output_dir/api/swagger-ui/swagger-ui-standalone-preset.js.LICENSE.txt"
cp openapi.yaml "$output_dir/openapi.yaml"
cp compatibility/versioning.md "$output_dir/versioning.md"
cp examples/send.md "$output_dir/examples/send.md"
cp examples/received.md "$output_dir/examples/received.md"
cp compatibility/frameworks/mediawiki.md "$output_dir/compatibility/frameworks/mediawiki.md"
cp compatibility/frameworks/wordpress.md "$output_dir/compatibility/frameworks/wordpress.md"
cp compatibility/frameworks/drupal.md "$output_dir/compatibility/frameworks/drupal.md"
cp compatibility/frameworks/symfony-laravel.md "$output_dir/compatibility/frameworks/symfony-laravel.md"
cp compatibility/languages/php.md "$output_dir/compatibility/languages/php.md"
cp compatibility/languages/go.md "$output_dir/compatibility/languages/go.md"
cp compatibility/languages/python.md "$output_dir/compatibility/languages/python.md"
cp compatibility/clouds/amazon-ses.md "$output_dir/compatibility/clouds/amazon-ses.md"
cp compatibility/clouds/gmail-api.md "$output_dir/compatibility/clouds/gmail-api.md"
cp compatibility/clouds/azure-email.md "$output_dir/compatibility/clouds/azure-email.md"
cp compatibility/clouds/resend.md "$output_dir/compatibility/clouds/resend.md"
cp compatibility/protocols/jmap.md "$output_dir/compatibility/protocols/jmap.md"
cp compatibility/protocols/smtp.md "$output_dir/compatibility/protocols/smtp.md"
