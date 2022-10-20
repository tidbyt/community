// Package kickstarter provides details for the Kickstarter applet.
package kickstarter

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed kickstarter.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Kickstarter applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "kickstarter",
		Name:        "Kickstarter",
		Author:      "sethvargo",
		Summary:     "Kickstarter project status",
		Desc:        "Display the total amount raised and the number of backers for a Kickstarter project. The project must be publicly visible.",
		FileName:    "kickstarter.star",
		PackageName: "kickstarter",
		Source:      source,
	}
}
