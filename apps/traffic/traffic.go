// Package traffic provides details for the Traffic applet.
package traffic

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed traffic.star
var source []byte

// New creates a new instance of the Traffic applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "traffic",
		Name:        "Traffic",
		Author:      "Rob Kimball",
		Summary:     "Time to your destination",
		Desc:        "Shows your estimated travel duration using traffic information from Bing/MapQuest.",
		FileName:    "traffic.star",
		PackageName: "traffic",
		Source:      source,
	}
}
