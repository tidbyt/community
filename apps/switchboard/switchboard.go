// Package switchboard provides details for the Switchboard applet.
package switchboard

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed switchboard.star
var source []byte

// New creates a new instance of the Switchboard applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "switchboard",
		Name:        "Switchboard",
		Author:      "bguggs",
		Summary:     "Display Switchboard data",
		Desc:        "Displays data from Switchboard on your Tidbyt.",
		FileName:    "switchboard.star",
		PackageName: "switchboard",
		Source:  source,
	}
}
