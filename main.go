package main

import "fmt"
import "unsafe"

//go:cgo_ldflag "-lsum"
//go:cgo_ldflag "-L."
//go:cgo_import_static sum
//go:linkname sum sum
var sum uintptr

//go:noescape
func one() int64

//go:noescape
func asmcgocall(fn, arg unsafe.Pointer)

var asmsysvicall6 uintptr

func main() {
	fmt.Printf("one()=%x\n", one())
	fmt.Printf("addr(sum)=%p\n", &sum)
	a, b := 40, 2
	res := sysvicall2(uintptr(unsafe.Pointer(&sum)), uintptr(a), uintptr(b))
	fmt.Printf("sum(%d,%d)=%d\n", a, b, res)
}

// Taken from runtime/runtime2.go (9b69196958a1ba3eba7a1621894ea9aafaa91648)

type libcall struct {
	fn   uintptr
	n    uintptr // number of parameters
	args uintptr // parameters
	r1   uintptr // return values
	r2   uintptr
	err  uintptr // error number
}

// Taken from runtime/os_solaris.go (9b69196958a1ba3eba7a1621894ea9aafaa91648)

func sysvicall2(fn uintptr, a1, a2 uintptr) uintptr {
	libcall := &libcall{}
	libcall.fn = uintptr(fn)
	libcall.n = 2
	libcall.args = uintptr(noescape(unsafe.Pointer(&a1)))
	asmcgocall(unsafe.Pointer(&asmsysvicall6), unsafe.Pointer(libcall))
	return libcall.r1
}

// Taken from runtime/stubs.go (9b69196958a1ba3eba7a1621894ea9aafaa91648)

// noescape hides a pointer from escape analysis.  noescape is
// the identity function but escape analysis doesn't think the
// output depends on the input.  noescape is inlined and currently
// compiles down to a single xor instruction.
// USE CAREFULLY!
//go:nosplit
func noescape(p unsafe.Pointer) unsafe.Pointer {
	x := uintptr(p)
	return unsafe.Pointer(x ^ 0)
}
