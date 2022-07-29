// Package nightscout provides details for the Nightscout applet.
package nightscout

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nightscout.star
var source []byte

// New creates a new instance of the Nightscout applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nightscout",
		Name:        "Nightscout",
		Author:      "Jeremy Tavener, Paul Murphy",
		Summary:     "Shows Nightscout CGM Data",
		Desc:        "Displays Continuous Glucose Monitoring (CGM) data from the Nightscout Open Source project (https://nightscout.github.io/).",
		FileName:    "nightscout.star",
		PackageName: "nightscout",
		Source:      source,
	}
}
