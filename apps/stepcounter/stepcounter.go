// Package stepcounter provides details for the Step Counter applet.
package stepcounter

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed stepcounter.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Step Counter applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "step-counter",
		Name:        "Step Counter",
		Author:      "Matt-Pesce",
		Summary:     "Tracks Daily Step Progress",
		Desc:        "Fetches your Step Data from Google Fit, Reports progress versus daily goal.",
		FileName:    "stepcounter.star",
		PackageName: "stepcounter",
		Source:      source,
	}
}
