// Package nightscout2.0 provides details for the Nightscout 2.0 applet.
package nightscout2.0

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nightscout_2.0.star
var source []byte

// New creates a new instance of the Nightscout 2.0 applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nightscout-2.0",
		Name:        "Nightscout 2.0",
		Author:      "Jeremy Tavener, Paul Murphy",
		Summary:     "Shows Nightscout CGM Data",
		Desc:        "Displays Continuous Glucose Monitoring (CGM) data from the Nightscout Open Source project (https://nightscout.github.io/).",
		FileName:    "nightscout_2.0.star",
		PackageName: "nightscout2.0",
		Source:  source,
	}
}
