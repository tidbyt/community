// Package newapps provides details for the New Apps applet.
package newapps

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed new_apps.star
var source []byte

// New creates a new instance of the New Apps applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "new-apps",
		Name:        "New Apps",
		Author:      "rs7q5",
		Summary:     "Lists new Tidbyt apps",
		Desc:        "Lists new Tidbyt apps within the last week.",
		FileName:    "new_apps.star",
		PackageName: "newapps",
		Source:  source,
	}
}
