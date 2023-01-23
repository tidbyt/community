// Package ncaamstandings provides details for the NCAAM Standings applet.
package ncaamstandings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ncaam_standings.star
var source []byte

// New creates a new instance of the NCAAM Standings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ncaam-standings",
		Name:        "NCAAM Standings",
		Author:      "LunchBox8484",
		Summary:     "NCAAM football standings",
		Desc:        "View NCAAM standings by conference.",
		FileName:    "ncaam_standings.star",
		PackageName: "ncaamstandings",
		Source:  source,
	}
}
