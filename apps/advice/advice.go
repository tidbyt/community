// Package advice provides details for the Advice applet.
package advice

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed advice.star
var source []byte

// New creates a new instance of the Advice applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "advice",
		Name:        "Advice",
		Author:      "mrrobot245",
		Summary:     "Random advice API",
		Desc:        "Shows random advice from AdviceSlip.com.",
		FileName:    "advice.star",
		PackageName: "advice",
		Source:  source,
	}
}
