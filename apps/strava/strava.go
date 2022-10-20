// Package strava provides details for the Strava applet.
package strava

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed strava.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Strava applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "strava",
		Name:        "Strava",
		Author:      "Rob Kimball",
		Summary:     "Displays athlete stats",
		Desc:        "Displays your YTD or all-time athlete stats recorded on Strava.",
		FileName:    "strava.star",
		PackageName: "strava",
		Source:      source,
	}
}
