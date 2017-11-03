// Driver to Javascript Archive (jsar) files
package main

import (
	"archive/tar"
	"compress/gzip"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"path"
	"strings"

	"vistarmedia.com/rules_js/js/tools/jsar"
)

func init() {
	log.SetPrefix("[jsar] ")
	log.SetFlags(log.LstdFlags | log.Lshortfile)
}

func bundle(cmd string, args []string) error {
	var (
		flagSet    = flag.NewFlagSet(cmd, flag.ExitOnError)
		outputName = flagSet.String("output", "", "output jsar")
	)

	if err := flagSet.Parse(args); err != nil {
		return err
	}

	writer, err := jsar.CreateWriter(*outputName)
	if err != nil {
		return err
	}
	for _, arg := range flagSet.Args() {
		srcDst := strings.Split(arg, "=")
		if err := writer.AddFile(srcDst[0], srcDst[1]); err != nil {
			return err
		}
	}
	return writer.Close()
}

func unbundleTo(jsarpath, dstpath string) error {
	file, err := os.Open(jsarpath)
	if err != nil {
		return err
	}
	defer file.Close()
	r, err := jsar.NewReader(file)
	if err != nil {
		return err
	}

	for {
		info, err := r.Next()
		if err == io.EOF {
			break
		} else if err != nil {
			return err
		}

		dst := path.Join(dstpath, info.Name)
		dir := path.Dir(dst)

		stat, err := os.Stat(dir)
		if err != nil || !stat.IsDir() {
			if err := os.MkdirAll(dir, 0755); err != nil {
				return err
			}
		}

		w, err := os.OpenFile(dst, os.O_CREATE|os.O_WRONLY, 0660)
		if err != nil {
			return err
		}
		if _, err := io.Copy(w, r); err != nil {
			w.Close()
			return err
		}
		w.Close()
	}

	return r.Close()
}

func unbundle(cmd string, args []string) error {
	var (
		flagSet = flag.NewFlagSet(cmd, flag.ExitOnError)
		output  = flagSet.String("output", "", "output root directory")
	)
	if err := flagSet.Parse(args); err != nil {
		return err
	}
	if flagSet.NArg() < 1 {
		return errors.New("unbundle -output root <jsar>")
	}

	for _, jsar := range flagSet.Args() {
		if err := unbundleTo(jsar, *output); err != nil {
			return err
		}
	}

	return nil
}

func fromtarball(cmd string, args []string) error {
	var (
		flagSet = flag.NewFlagSet(cmd, flag.ExitOnError)
		output  = flagSet.String("output", "", "output jsar file")
	)
	if err := flagSet.Parse(args); err != nil {
		return err
	}
	if flagSet.NArg() < 1 {
		return errors.New("fromtarball -output lib.jsar <src.tgz>")
	}

	writer, err := jsar.CreateWriter(*output)
	if err != nil {
		return err
	}
	for _, arg := range flagSet.Args() {
		src, err := os.Open(arg)
		if err != nil {
			return err
		}
		defer src.Close()
		r, err := gzip.NewReader(src)
		if err != nil {
			return err
		}

		tr := tar.NewReader(r)
		for {
			hdr, err := tr.Next()
			if err == io.EOF {
				break
			}
			if err != nil {
				return err
			}
			if hdr.Typeflag != tar.TypeReg {
				continue
			}
			name := hdr.Name
			if strings.HasPrefix(name, "./") {
				name = name[1:]
			} else if !strings.HasPrefix(name, "/") {
				name = "/" + name
			}

			info := &jsar.FileInfo{
				Name: name,
				Size: hdr.Size,
			}
			if err := writer.Add(info, tr); err != nil {
				return err
			}
		}

	}
	return writer.Close()
}

func usage(args []string) {
	fmt.Fprintf(os.Stderr, "USAGE: %s (bundle|unbundle|fromtarball)\n", args[0])
	os.Exit(2)
}

func main() {
	args := os.Args

	if len(args) < 2 {
		usage(args)
	}

	var err error
	switch cmd := args[1]; cmd {
	default:
		fmt.Fprintf(os.Stderr, "invalid command '%s'\n", cmd)
		usage(args)

	case "bundle":
		err = bundle(args[0], args[2:])

	case "unbundle":
		err = unbundle(args[0], args[2:])

	case "fromtarball":
		err = fromtarball(args[0], args[2:])
	}

	if err != nil {
		log.Fatal(err)
	}
}
