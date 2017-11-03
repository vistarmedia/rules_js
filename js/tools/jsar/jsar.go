// A simple on-disk Javascript Archive (jsar) format which can be gzipped and
// concatenated easily. It bypasses many of the features of `tar` to be a
// small-and-fast archive format.
//
// It does not support file creation or modification times. Neither does it
// support permissions. All files and directories which may be created are set
// with the defaults of their parent directories.
//
// While something like protobuf may be better to represent the header, json is
// used here  to minimize dependencies. The layout of single entry is as
// follows:
//
//    +-----------------------+--------+----------+
//    | uvarint header length | header | bytes... |
//    +-----------------------+--------+----------+
//
// Given a file containing `Party Every Day!` (a length of 16) at the location
// `/some/cool/path`, the header would be `{"n":"/some/cool/path","s":16}` (a
// length of 30). This would give the following `jsar` contents.
//
//    +----+---------------------+------------------+
//    | 1e | {"n":"/some/cool... | Party Every D... |
//    +----+---------------------+------------------+
//    |    |                     |
//    |    |                     +--- File contents
//    |    +------------------------- JSON header
//    +------------------------------ Varint header length
//
// The format is simply a repeated number of file entries as specified above.
package jsar

import (
	"bufio"
	"compress/gzip"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
)

func writeUvarint(w io.Writer, i uint64) (int, error) {
	buf := make([]byte, binary.MaxVarintLen64)
	length := binary.PutUvarint(buf, i)
	return w.Write(buf[:length])
}

type FileInfo struct {
	Name string `json:"n"`
	Size int64  `json:"s"`
}

func (fi *FileInfo) Write(w io.Writer) (int, error) {
	header, err := json.Marshal(fi)
	if err != nil {
		return 0, err
	}

	if n, err := writeUvarint(w, uint64(len(header))); err != nil {
		return n, err
	}

	return w.Write(header)
}

// Writes `jsar` files to an underlying io.Writer.
type Writer struct {
	w *gzip.Writer
}

func NewWriter(compressed io.Writer) (*Writer, error) {
	w, err := gzip.NewWriterLevel(compressed, gzip.BestCompression)
	if err != nil {
		return nil, err
	}
	return &Writer{w}, nil
}

func CreateWriter(dst string) (*Writer, error) {
	file, err := os.Create(dst)
	if err != nil {
		return nil, err
	}
	return NewWriter(file)
}

func (w *Writer) AddFile(src, dst string) error {
	stat, err := os.Stat(src)
	if err != nil {
		return err
	}

	if stat.IsDir() {
		return fmt.Errorf("%s is not a file. Invalid jsar entry", src)
	}

	fileInfo := &FileInfo{
		Name: dst,
		Size: stat.Size(),
	}

	file, err := os.Open(src)
	if err != nil {
		return err
	}
	defer file.Close()

	return w.Add(fileInfo, file)
}

func (w *Writer) Add(fi *FileInfo, r io.Reader) error {
	if !strings.HasPrefix(fi.Name, "/") {
		return fmt.Errorf("Destination '%s' is not fully qualified", fi.Name)
	}

	if _, err := fi.Write(w.w); err != nil {
		return err
	}
	_, err := io.Copy(w.w, r)
	return err
}

func (w *Writer) Close() error {
	if err := w.w.Flush(); err != nil {
		w.w.Close()
		return err
	}
	return w.w.Close()
}

// Reader for `jsar` files
type Reader struct {
	gzReader *gzip.Reader
	r        *bufio.Reader
	current  io.Reader
}

func NewReader(compressed io.Reader) (reader *Reader, err error) {
	r, err := gzip.NewReader(compressed)
	if err != nil {
		return
	}
	reader = &Reader{
		gzReader: r,
		r:        bufio.NewReader(r),
	}
	return
}

func (r *Reader) Next() (*FileInfo, error) {
	headerLen, err := binary.ReadUvarint(r.r)
	if err != nil {
		return nil, err
	}
	header := new(FileInfo)
	reader := io.LimitReader(r.r, int64(headerLen))
	err = json.NewDecoder(reader).Decode(header)
	if err == nil {
		r.current = io.LimitReader(r.r, int64(header.Size))
	}
	return header, err
}

func (r *Reader) Read(b []byte) (int, error) {
	return r.current.Read(b)
}

func (r *Reader) Close() error {
	return r.gzReader.Close()
}
