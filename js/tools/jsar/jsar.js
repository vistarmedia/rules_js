const zlib = require('zlib')

/**
 * Unbundles a jsar buffer and returns the files in memory
 * @param {Buffer} buffer - The jsar buffer
 * @returns {Object} A mapping of file name to file contents
 */
function unbundle(buffer) {
  return new Promise(function(resolve, reject){
    zlib.unzip(buffer, (error, buffer) => {
      if (error) {
        reject(error)
        return
      }
      let offset = 0
      const packages = {}
      while (offset < buffer.length) {
        try {
          const length = readUnsignedVarint32(buffer, offset)
          offset += length.length

          const jsonBuffer = buffer.slice(offset, offset + length.value)
          offset += length.value

          const json = JSON.parse(jsonBuffer)
          const fileContentsBuffer = buffer.slice(offset, offset + json.s)
          offset += json.s

          packages[json.n] = fileContentsBuffer.toString()
        } catch(err) {
          reject(err)
          return
        }
      }
      resolve(packages)
    })
  })
}

function readUnsignedVarint32(a, offset) {
  let b;
  let result = 0;
  let intOffset = 0

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
  unbundle
}
