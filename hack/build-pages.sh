#!/usr/bin/env bash

set -euo pipefail

output_dir="${1:-public}"

if [[ "$output_dir" == /* || "$output_dir" == "." || "$output_dir" == ".." || "$output_dir" == *".."* ]]; then
  echo "Output directory must be a safe relative path." >&2
  exit 1
fi

rm -rf -- "$output_dir"
mkdir -p "$output_dir/compatibility" "$output_dir/transports"

cp site/_config.yml "$output_dir/_config.yml"
cp site/index.md "$output_dir/index.md"
cp openapi.yaml "$output_dir/openapi.yaml"
cp docs/versioning.md "$output_dir/versioning.md"
cp docs/compatibility/mediawiki.md "$output_dir/compatibility/mediawiki.md"
cp docs/compatibility/wordpress.md "$output_dir/compatibility/wordpress.md"
cp docs/compatibility/drupal.md "$output_dir/compatibility/drupal.md"
cp docs/compatibility/symfony-laravel.md "$output_dir/compatibility/symfony-laravel.md"
cp docs/transports/smtp.md "$output_dir/transports/smtp.md"
