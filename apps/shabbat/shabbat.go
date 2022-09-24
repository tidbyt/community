// Package shabbat provides details for the Shabbat applet.
package shabbat

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shabbat.star
var source []byte

// New creates a new instance of the Shabbat applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shabbat",
		Name:        "Shabbat",
		Author:      "dinosaursrarr",
		Summary:     "Start and end of Shabbat",
		Desc:        "Shows the start and end times of the current or upcoming Shabbat observance.",
		FileName:    "shabbat.star",
		PackageName: "shabbat",
		Source:  source,
	}
}
