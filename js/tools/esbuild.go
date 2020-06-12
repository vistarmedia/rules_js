package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"github.com/evanw/esbuild/pkg/api"
	"vistarmedia.com/rules_js/js/tools/jsar"
)

type EsbuildOptions struct {
	Entrypoint string
	Outfile    string
	Defines    map[string]string
	Minify     bool
	Sourcemap  bool
}

func main() {
	if _, err := os.Stat("./node_modules"); !os.IsNotExist(err) {
		panic("bazel sandbox node_modules already exists")
	}
	var esbuildOptions EsbuildOptions

	// unpack jsars into node_modules folder
	for _, arg := range os.Args {
		if strings.HasPrefix(arg, "--jsar=") {
			jsarPath := arg[len("--jsar="):]
			err := jsar.UnbundleTo(jsarPath, "./node_modules")
			if err != nil {
				panic(err)
			}
		} else {
			json.Unmarshal([]byte(arg), &esbuildOptions)
		}
	}

	sourcemap := api.SourceMapNone
	if esbuildOptions.Sourcemap {
		sourcemap = api.SourceMapExternal
	}

	result := api.Build(api.BuildOptions{
		EntryPoints: []string{fmt.Sprintf("./node_modules/%s", esbuildOptions.Entrypoint)},
		Outfile:     esbuildOptions.Outfile,
		Bundle:      true,
		Defines:     esbuildOptions.Defines,

		MinifyWhitespace:  esbuildOptions.Minify,
		MinifyIdentifiers: esbuildOptions.Minify,
		MinifySyntax:      esbuildOptions.Minify,

		Sourcemap: sourcemap,
	})

	for _, e := range result.Errors {
		fmt.Printf("%s at %s\n", e.Text, e.Location.File)
	}
	for _, e := range result.Warnings {
		fmt.Printf("%s at %s\n", e.Text, e.Location.File)
	}
	if len(result.Errors) > 0 {
		os.Exit(1)
	}

	for _, out := range result.OutputFiles {
		err := ioutil.WriteFile(out.Path, out.Contents, 0644)
		if err != nil {
			panic(err)
		}
	}
}
