#!/usr/bin/env bash

set -e

echo ""
echo "Copying dependencies..."

for i in rules/*; do
  cp -r src $i
done

echo ""
