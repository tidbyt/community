// Package launchcountdown provides details for the LaunchCountdown applet.
package launchcountdown

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed launchcountdown.star
var source []byte

// New creates a new instance of the LaunchCountdown applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "launchcountdown",
		Name:        "LaunchCountdown",
		Author:      "Robert Ison",
		Summary:     "Displays next world launch",
		Desc:        "Displays the next rocket launch in the world.",
		FileName:    "launchcountdown.star",
		PackageName: "launchcountdown",
		Source:  source,
	}
}
