JS Persistent Workers
=====================
The documentation around Bazel persistent workers is light. Basically, you need
a binary that has two modes of operation...


## One-shot worker
Bazel may choose to invoke the worker for exactly one task in one-shot mode.
When making this choice, the worker will be invoked with a single command-line
argument like:

    ./yourBinary --flagfile=bazel-bin/path/to/your.args

The encoding of that file is entirely up to you. You must encode your arguments
and write them to a file as part of the Bazel rule which calls your worker. It
is the worker's responsibility to parse the above argument, go read the file,
and continue its work.

No other out-of-the-ordinary requirements are put on this process.

## Persistent worker
A rule tells Bazel that a binary is able to be persisted by passing
`execution_requirements = { "supports-workers": "1" }` to `ctx.actions.run`.
Then, Bazel may invoke that binary in persisted mode as follows:

    ./yourBinary --persistent_worker

In this case, the process' `stdin` and `stdout` are owned by the Bazel process.
Bazel will send a varint-delimited
[`WorkRequest`](https://github.com/bazelbuild/bazel/blob/master/src/main/protobuf/worker_protocol.proto)
to the process in the following shape:


    // This represents a single work unit that Blaze sends to the worker.
    message WorkRequest {
      repeated string arguments = 1;

      // The inputs that the worker is allowed to read during execution of this
      // request.
      repeated Input inputs = 2;
    }

    // An input file.
    message Input {
      // The path in the file system where to read this input artifact from.
      // This is either a path relative to the execution root (the worker
      // process is launched with the working directory set to the execution
      // root), or an absolute path.
      string path = 1;

      // A hash-value of the contents. The format of the contents is unspecified
      // and the digest should be treated as an opaque token.
      bytes digest = 2;
    }

Somewhat confusingly, the `arguments` field of the `WorkRequest` is not your
initial arguments, but will be (as per the example above)
`--flagfile=bazel-bin/path/to/your.args`

The worker follow the same logic as the stand-alone example above. However,
instead of printing anything to `stdout` or ending the process, it should make a
`WorkResponse`, and write that to `stdout`. This is the same regardless of if
the work succeeded or failed. Bazel will shuttle this information back to the
user.

    // The worker sends this message to Blaze when it finished its work on the
    // WorkRequest message.
    message WorkResponse {
      int32 exit_code = 1;

      // This is printed to the user after the WorkResponse has been received
      // and is supposed to contain compiler warnings / errors etc. - thus we'll
      // use a string type here, which gives us UTF-8 encoding.
      string output = 2;
    }

Bazel will close `stdin` when it wants a worker to shut down.

## Gotchas
Bazel may capture `stderr` and spool it to disk for debugging. However, if a
piece of work writes to `stdout`, it will screw up the communication channel to
Bazel, and the process will likely crash. When writing workers, you need to be
careful to accumulte and return output rather than print it.

persistent\_worker Library
==========================
This library abstracts most of the above away for you. You still need to make
sure to accumulate output and have an error code, but most other glue is
provided for you. You must provide a function that takes the contents of the
`flagfile` above, and returns an object with the shape of `{exitCode: int,
output: string}`. See [index.js](./index.js) in this directory for more
information.
