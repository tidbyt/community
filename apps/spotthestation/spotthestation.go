// Package spotthestation provides details for the SpotTheStation applet.
package spotthestation

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed spotthestation.star
var source []byte

// New creates a new instance of the SpotTheStation applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "spotthestation",
		Name:        "SpotTheStation",
		Author:      "Robert Ison",
		Summary:     "Next ISS visit overhead",
		Desc:        "Displays the next time the International Space Station will appear.",
		FileName:    "spotthestation.star",
		PackageName: "spotthestation",
		Source:  source,
	}
}
