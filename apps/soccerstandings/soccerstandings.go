// Package soccerstandings provides details for the Soccer Standings applet.
package soccerstandings

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed soccer_standings.star
var source []byte

// New creates a new instance of the Soccer Standings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "soccer-standings",
		Name:        "Soccer Standings",
		Author:      "M0ntyP",
		Summary:     "Shows tables",
		Desc:        "Displays league standings from around Europe and the world. Users have a choice of showing black & white or with team colours as the background of the row",
		FileName:    "soccer_standings.star",
		PackageName: "soccerstandings",
		Source:  source,
	}
}
