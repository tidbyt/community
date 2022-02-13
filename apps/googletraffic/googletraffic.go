// Package googletraffic provides details for the Google Traffic applet.
package googletraffic

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed google_traffic.star
var source []byte

// New creates a new instance of the Google Traffic applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "google-traffic",
		Name:        "Google Traffic",
		Author:      "LukiLeu",
		Summary:     "Drive Duration in Traffic",
		Desc:        "This app shows the duration to get from an origin to a destination by using traffic information from Google.",
		FileName:    "google_traffic.star",
		PackageName: "googletraffic",
		Source:  source,
	}
}
