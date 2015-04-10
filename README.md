# go-static

This is a sandbox for trying out:

* Linking Go applications against static libraries.
* Calling C functions without using CGO.

Requires [go1.4beta1-1732-g9b69196](https://github.com/golang/go/tree/9b69196958a1ba3eba7a1621894ea9aafaa91648) because of generated `go_asm.h`.

Thanks to Solaris port which implemented SysV ABI compatible wrappers.

Demo: `make`.
