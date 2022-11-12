// Package statesvisited provides details for the States Visited applet.
package statesvisited

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed states_visited.star
var source []byte

// New creates a new instance of the States Visited applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "states-visited",
		Name:        "States Visited",
		Author:      "sloanesturz",
		Summary:     "Show states you've visited",
		Desc:        "Select the states you have been to and show them off on your Tidbyt!",
		FileName:    "states_visited.star",
		PackageName: "statesvisited",
		Source:      source,
	}
}
