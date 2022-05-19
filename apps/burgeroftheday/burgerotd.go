// Package burgerotd provides details for the Burger of the Day applet.
package burgerotd

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed burgerotd.star
var source []byte

// New creates a new instance of the Burger of the Day applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "burgerotd",
		Name:        "Burger of the Day",
		Author:      "Kyle Stark",
		Summary:     "Shows Burger of the Day",
		Desc:        "Display the set Burger of the Day, show a random burger every time, or enter your own custom burger. Burgers courtesy of Bob's Burgers. Use the "Show logo" and "Scroll speed" options to fit your Tidbyt.",
		FileName:    "burgerotd.star",
		PackageName: "burgerotd",
		Source:  source,
	}
}