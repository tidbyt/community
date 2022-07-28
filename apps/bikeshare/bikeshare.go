// Package bikeshare provides details for the Bikeshare applet.
package bikeshare

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed bikeshare.star
var source []byte

// New creates a new instance of the Bikeshare applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "bikeshare",
		Name:        "Bikeshare",
		Author:      "snorremd",
		Summary:     "Bikeshare availability",
		Desc:        "Shows bike and parking availability for user selected bikeshare locations.",
		FileName:    "bikeshare.star",
		PackageName: "bikeshare",
		Source:  source,
	}
}
