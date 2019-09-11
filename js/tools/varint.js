function readUnsignedVarint32(a, offset) {
  let b;
  let result = 0;
  let intOffset = 0;

  for (let i = 0; i < 5; i++) {
    b = a[offset + intOffset++];
    result |= (b & 0x7f) << (7 * i);
    if (!(b & 0x80)) {
      break;
    }
  }

  return { value: result, length: intOffset };
}

function writeUnsignedVarint32(buf, value) {
  let i = 0;
  while (value >= 0x80) {
    buf[i] = value | 0x80;
    value >>= 7;
    i++;
  }
  buf[i] = value;
  return i + 1;
}

module.exports = {
  readUnsignedVarint32,
  writeUnsignedVarint32
};
