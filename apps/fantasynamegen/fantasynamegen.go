// Package fantasynamegen provides details for the FantasyNameGen applet.
package fantasynamegen

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed fantasynamegen.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the FantasyNameGen applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "fantasynamegen",
		Name:        "FantasyNameGen",
		Author:      "Ryan Allison",
		Summary:     "Generate fantasy names",
		Desc:        "Randomly generate fantasy/RPG characters.",
		FileName:    "fantasynamegen.star",
		PackageName: "fantasynamegen",
		Source:      source,
	}
}
