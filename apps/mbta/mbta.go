// Package mbta provides details for the MBTA applet.
package mbta

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mbta.star
var source []byte

// New creates a new instance of the MBTA applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mbta",
		Name:        "MBTA",
		Author:      "Marcus Better",
		Summary:     "MBTA departures",
		Desc:        "MBTA bus and rail departure times.",
		FileName:    "mbta.star",
		PackageName: "mbta",
		Source:  source,
	}
}
