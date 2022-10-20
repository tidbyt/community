// Package londonbusstop provides details for the London Bus Stop applet.
package londonbusstop

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed london_bus_stop.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the London Bus Stop applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "london-bus-stop",
		Name:        "London Bus Stop",
		Author:      "dinosaursrarr",
		Summary:     "Upcoming arrivals",
		Desc:        "Shows upcoming arrivals at a specific bus stop in London.",
		FileName:    "london_bus_stop.star",
		PackageName: "londonbusstop",
		Source:      source,
	}
}
