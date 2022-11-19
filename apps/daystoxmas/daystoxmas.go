// Package daystoxmas provides details for the Days to Xmas applet.
package daystoxmas

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed days_to_xmas.star
var source []byte

// New creates a new instance of the Days to Xmas applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "days-to-xmas",
		Name:        "Days to Xmas",
		Author:      "Godfrey Systems Web Development",
		Summary:     "Displays Days to Xmas",
		Desc:        "Display a countdown of days left til Christmas Day.",
		FileName:    "days_to_xmas.star",
		PackageName: "daystoxmas",
		Source:  source,
	}
}
