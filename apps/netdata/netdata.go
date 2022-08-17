// Package netdata provides details for the Netdata applet.
package netdata

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed netdata.star
var source []byte

// New creates a new instance of the Netdata applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "netdata",
		Name:        "Netdata",
		Author:      "MrRobot245",
		Summary:     "Stuff",
		Desc:        "Stuff 2.",
		FileName:    "netdata.star",
		PackageName: "netdata",
		Source:  source,
	}
}
