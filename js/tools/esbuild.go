package main

import (
	"fmt"
	"os"
	"strings"

	cmd "github.com/tooolbox/esbuild/src/esbuild/main"
	"vistarmedia.com/rules_js/js/tools/jsar"
)

func main() {
	args := make([]string, 0, len(os.Args))
	if _, err := os.Stat("./node_modules"); !os.IsNotExist(err) {
		panic("bazel sandbox node_modules already exists")
	}

	// rewrite some of the args, unbundling the jsar paths
	for _, arg := range os.Args {
		if strings.HasPrefix(arg, "--jsar=") {
			jsarPath := arg[len("--jsar="):]
			err := jsar.UnbundleTo(jsarPath, "./node_modules")
			if err != nil {
				panic(err)
			}
		} else if strings.HasPrefix(arg, "--entrypoint") {
			entrypoint := arg[len("--entrypoint="):]
			args = append(args, fmt.Sprintf("./node_modules/%s", entrypoint))
		} else {
			args = append(args, arg)
		}
	}

	os.Args = args
	cmd.Run()
}
