package main

import (
	"os"

	"tidbyt.dev/community/tools/cmd"
)

func main() {
	err := cmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}
