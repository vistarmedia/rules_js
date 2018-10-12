const zlib = require('zlib')

const {readUnsignedVarint32} = require('../varint');

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


module.exports = {
  unbundle,
}
