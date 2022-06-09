// Package stateflags provides details for the State Flags applet.
package stateflags

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed state_flags.star
var source []byte

// New creates a new instance of the State Flags applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "state-flags",
		Name:        "State Flags",
		Author:      "Robert Ison",
		Summary:     "State Flags",
		Desc:        "Displays state flags.",
		FileName:    "state_flags.star",
		PackageName: "stateflags",
		Source:  source,
	}
}
