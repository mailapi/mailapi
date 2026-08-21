#!/usr/bin/env bash

set -euo pipefail

output_dir="${1:-public}"

if [[ "$output_dir" == /* || "$output_dir" == "." || "$output_dir" == ".." || "$output_dir" == *".."* ]]; then
  echo "Output directory must be a safe relative path." >&2
  exit 1
fi

rm -rf -- "$output_dir"
mkdir -p "$output_dir/frameworks" "$output_dir/languages" "$output_dir/transports"

cp site/_config.yml "$output_dir/_config.yml"
cp site/index.md "$output_dir/index.md"
cp openapi.yaml "$output_dir/openapi.yaml"
cp docs/versioning.md "$output_dir/versioning.md"
cp docs/frameworks/mediawiki.md "$output_dir/frameworks/mediawiki.md"
cp docs/frameworks/wordpress.md "$output_dir/frameworks/wordpress.md"
cp docs/frameworks/drupal.md "$output_dir/frameworks/drupal.md"
cp docs/frameworks/symfony-laravel.md "$output_dir/frameworks/symfony-laravel.md"
cp docs/languages/php.md "$output_dir/languages/php.md"
cp docs/languages/go.md "$output_dir/languages/go.md"
cp docs/languages/python.md "$output_dir/languages/python.md"
cp docs/transports/smtp.md "$output_dir/transports/smtp.md"
