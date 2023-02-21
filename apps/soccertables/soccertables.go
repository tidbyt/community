// Package soccertables provides details for the Soccer Tables applet.
package soccertables

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed soccer_tables.star
var source []byte

// New creates a new instance of the Soccer Tables applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "soccer-tables",
		Name:        "Soccer Tables",
		Author:      "M0ntyP",
		Summary:     "Displays league tables",
		Desc:        "Displays league tables from soccer leagues, showing team abbreviation, record in W-D-L format and points total. Choose your league and choose if you want to display the team color or just white text on black.",
		FileName:    "soccer_tables.star",
		PackageName: "soccertables",
		Source:  source,
	}
}
