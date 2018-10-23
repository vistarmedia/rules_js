const protobuf = require('protobufjs');
const fs = require('fs');
const util = require('util');

const {readUnsignedVarint32} = require('../varint');

const readFile = util.promisify(fs.readFile);

const def     = require('./worker_protocol');
const builder = protobuf.newBuilder({});
const type    = builder.import(def).build().blaze.worker;

const {WorkRequest, WorkResponse} = type;


// @private
function readWorkRequests(src, onWork, resolve, reject) {
  let data = null;
  let dataOffset = 0;

  src.on('data', async (chunk) => {
    if(data === null) {
      // This is the first chunk of the WorkRequest.
      const size = readUnsignedVarint32(chunk, 0);
      const messageSize = size.value;
      if(messageSize <= chunk.length - size.length) {
        data = chunk.slice(size.length, size.length + messageSize);
        dataOffset = data.length;
      } else {
        data = Buffer.allocUnsafe(messageSize);
        dataOffset = chunk.copy(data, 0, size.length);
      }
    } else {
      // This is an additional part of the message. Append it to `data`
      dataOffset += chunk.copy(data, dataOffset);
    }

    // Keep reading until we have an entire WorkRequest
    if(dataOffset < data.length) {
      return;
    }

    const request = WorkRequest.decode(data);
    try {
      await onWork(request);
    } catch(err) {
      reject(err);
    }
    data = null;
  })

  src.on('end', () => {
    resolve();
  });
}

// @private
function writeWorkResponse(out, response) {
  const {exitCode, output} = response;
  out.write(
    new WorkResponse({exit_code: exitCode, output: output})
      .encodeDelimited()
      .toBuffer());
}

// @private
async function readWorkInput(flag, arg) {
  return await readFile(arg.slice(flag.length));
}

/**
 * See documentation for `work` below
 * @private
 */
async function workUnsafe(fun, flagPrefix="--flagfile=", argv=process.argv) {
  const args    = argv.slice(2);
  const input   = process.stdin;
  const output  = process.stdout;
  const safeFun = async (workInput) => {
    try {
      return await fun(workInput);
    } catch (err) {
      return {exitCode: 1, output: err.stack};
    }
  }

  // Ensure that there's only one argument. Bail if anything else seems to be
  // the case.
  if(args.length !== 1) {
    const msg = `${argv[1]} expected exactly 1 argument, ` +
                `got ${args.length}: ${JSON.stringify(args)}`;
    throw Error(msg);
  }
  const arg = args[0];

  // Running one-shot
  if(arg.startsWith(flagPrefix)) {
    const workInput = await readWorkInput(flagPrefix, arg);
    const {errorCode, output} = await safeFun(workInput);
    if(output) {
      console.log(output);
    }
    process.exit(errorCode);
  }

  // Running persistent
  if(arg === '--persistent_worker') {
    const onWork = async (request) => {
      const arg = request.arguments[0];
      const workInput = await readWorkInput(flagPrefix, arg);
      writeWorkResponse(output, await safeFun(workInput));
    }
    return new Promise((resolve) => {
      readWorkRequests(input, onWork, resolve);
    });
  }

  throw Error(`unexpected flags: ${JSON.stringify(args)}`);
}

/**
 * Runs a unit of work as either a one-shot or persisted worker. The given
 * function is assumed to be asynchronous, and *must* return a value in the shape
 * of `{errorCode: int, output: string}`. At present, a worker must accept only
 * one argument on the command line. Either an instruction to run persistent, or
 * the location of its arguments.
 *
 * If the executable is launched with `--persistent_worker` as any of the given
 * arguments, it will be persistent. As it stands, this must be the only
 * argument.
 *
 * The executable *must* be created with its arguments in a file, rather than
 * passed by the command-line.
 *
 * Bazel requires that a `flagPrefix` either be `--flagfile=` or `@`. Any value
 * will be respected here, but values outside of that will not be respected by
 * Bazel.
 */
async function work() {
  try {
    await workUnsafe.apply(null, arguments);
    process.exit(0);
  } catch(err) {
    console.error(err.stack);
    process.exit(2);
  }
}

module.exports = {work};
