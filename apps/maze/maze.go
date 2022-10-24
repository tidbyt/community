// Package maze provides details for the Maze applet.
package maze

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed maze.star
var source []byte

// New creates a new instance of the Maze applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "maze",
		Name:        "Maze",
		Author:      "gstark",
		Summary:     "Draws and solves mazes",
		Desc:        "Draws a maze and then animates solving the maze.",
		FileName:    "maze.star",
		PackageName: "maze",
		Source:  source,
	}
}
