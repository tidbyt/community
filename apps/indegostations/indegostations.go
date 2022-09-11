// Package indegostations provides details for the Indego Stations applet.
package indegostations

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed indego_stations.star
var source []byte

// New creates a new instance of the Indego Stations applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "indego-stations",
		Name:        "Indego Stations",
		Author:      "RayPatt",
		Summary:     "Indego station availability",
		Desc:        "The user selects an Indego (Philadelphia bike share) station and Tidbyt will regularly display the number of regular and electric bikes available.",
		FileName:    "indego_stations.star",
		PackageName: "indegostations",
		Source:  source,
	}
}
