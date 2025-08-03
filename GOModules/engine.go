package main

import "C"

//export GetGreeting
func GetGreeting() *C.char {
    return C.CString("Hello from Go!")
}

func main() {}