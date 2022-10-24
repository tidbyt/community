// Package fishbyt provides details for the Fishbyt applet.
package fishbyt

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed fishbyt.star
var source []byte

// New creates a new instance of the Fishbyt applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "fishbyt",
		Name:        "Fishbyt",
		Author:      "vlauffer",
		Summary:     "Fish facts",
		Desc:        "Gaze upon glorious marine life.",
		FileName:    "fishbyt.star",
		PackageName: "fishbyt",
		Source:  source,
	}
}
