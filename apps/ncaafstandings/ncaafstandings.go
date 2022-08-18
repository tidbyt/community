// Package ncaafstandings provides details for the NCAAF Standings applet.
package ncaafstandings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ncaaf_standings.star
var source []byte

// New creates a new instance of the NCAAF Standings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ncaaf-standings",
		Name:        "NCAAF Standings",
		Author:      "LunchBox8484",
		Summary:     "NCAAF football standings",
		Desc:        "View NCAAF standings by conference.",
		FileName:    "ncaaf_standings.star",
		PackageName: "ncaafstandings",
		Source:  source,
	}
}
