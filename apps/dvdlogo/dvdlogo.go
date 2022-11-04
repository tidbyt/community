// Package dvdlogo provides details for the DVD Logo applet.
package dvdlogo

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed dvd_logo.star
var source []byte

// New creates a new instance of the DVD Logo applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "dvd-logo",
		Name:        "DVD Logo",
		Author:      "Mack Ward",
		Summary:     "Bouncing DVD Logo",
		Desc:        "A screensaver from before the streaming era. Will it hit the corner this time?",
		FileName:    "dvd_logo.star",
		PackageName: "dvdlogo",
		Source:  source,
	}
}
