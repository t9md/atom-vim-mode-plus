package main

import "fmt"
import "os"

func main() {
	d1 := 1
	d2 := 2
	s1 := "s1"
	s2 := "s2"

	if (os.Args[1] == "str") {
		fmt.Printf("%s\n", s1)
		fmt.Printf("%s\n", s2)
	} else {
		fmt.Printf("%d\n", d1)
		fmt.Printf("%d\n", d2)
	}
}
