// Package tautulli provides details for the Tautulli applet.
package tautulli

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed tautulli.star
var source []byte

// New creates a new instance of the Tautulli applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "tautulli",
		Name:        "Tautulli",
		Author:      "MrRobot245",
		Summary:     "Shows stream info",
		Desc:        "Shows your current sessions stream count, broken up into transcodes/direct steams as an option. Also shows total upload bandwidth in Mbps.",
		FileName:    "tautulli.star",
		PackageName: "tautulli",
		Source:  source,
	}
}
