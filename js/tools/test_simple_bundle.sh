#!/bin/bash -eu
set -o pipefail
HEXDUMP="python -c \"print raw_input().decode('hex'),\""

JSAR=$(find -L . -executable -name jsar-bin)
OUTPUT="output.jsar"

# Copy "Party Every Day!" into a file named `src_file` and inspect its bundled
# output.
echo -n "Party Every Day!" > src_file
$JSAR bundle -output $OUTPUT src_file=/some/cool/path

# It should first have a header indicating its length in varint format
expected='1e'
actual=$(zcat $OUTPUT | head -c1 | python -c "print raw_input().encode('hex'),")
if [ "$expected" != "$actual" ] ; then
  echo "Expected '$expected' got '$actual'"
  exit 2
fi

# It should have a json header
expected='{"n":"/some/cool/path","s":16}'
actual=$(zcat $OUTPUT | tail -c +2 | head -c30)
if [ "$expected" != "$actual" ] ; then
  echo "Expected '$expected' got '$actual'"
  exit 2
fi

# It should contain the file contents
expected='Party Every Day!'
actual=$(zcat $OUTPUT | tail -c +32)
if [ "$expected" != "$actual" ] ; then
  echo "Expected '$expected' got '$actual'"
  exit 2
fi
