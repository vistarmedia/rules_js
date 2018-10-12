
function readUnsignedVarint32(a, offset) {
  let b;
  let result = 0;
  let intOffset = 0;

  for (let i = 0; i < 5; i++) {
    b = a[offset + intOffset++];
    result |= (b & 0x7F) << (7 * i);
    if (!(b & 0x80)) {
      break;
    }
  }

  return { value: result, length: intOffset };
}

module.exports = {
  readUnsignedVarint32
};
