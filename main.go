package main

import "fmt"

//go:noescape
func one() int64

func main() {
	fmt.Println(one())
}
