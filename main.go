package main

import "fmt"
import "unsafe"

//go:cgo_ldflag "-lsum"
//go:cgo_ldflag "-L."
//go:cgo_import_static sum
//go:linkname sum sum
var sum unsafe.Pointer

func main() {
	fmt.Printf("addr(sum)=%p\n", &sum)
}
