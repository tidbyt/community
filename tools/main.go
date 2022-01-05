package main

import (
	"fmt"
	"os"

	"tidbyt.dev/community/tools/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
