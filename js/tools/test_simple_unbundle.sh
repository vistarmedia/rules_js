#!/bin/bash -eu
set -o pipefail

JSAR=$(find -L . -executable -name jsar-bin)

# ------------------------------------------------------------------------------
# Create a nested bundle like
#
#   + root/
#   | + dir/
#   | | +- cats
#   | +- dogs
#   +- secrets
output=$TEST_TMPDIR/archive.jsar

mkdir -p $TEST_TMPDIR/root/dir

echo -n "Secrets!" > $TEST_TMPDIR/secrets
echo -n "Dogs!" > $TEST_TMPDIR/root/dogs
echo -n "Cats!" > $TEST_TMPDIR/root/dir/cats

$JSAR bundle -output $output \
  $TEST_TMPDIR/secrets=/secrets \
  $TEST_TMPDIR/root/dogs=/root/dogs \
  $TEST_TMPDIR/root/dir/cats=/root/dir/cats

# ------------------------------------------------------------------------------
# Unbundle the archive

$JSAR unbundle -output $TEST_TMPDIR/unbundled $output

expected='Secrets!'
actual=$(cat $TEST_TMPDIR/unbundled/secrets)
if [ "$expected" != "$actual" ] ; then
  echo "Expected '$expected' got '$actual'"
  exit 2
fi

expected='Cats!'
actual=$(cat $TEST_TMPDIR/unbundled/root/dir/cats)
if [ "$expected" != "$actual" ] ; then
  echo "Expected '$expected' got '$actual'"
  exit 2
fi
