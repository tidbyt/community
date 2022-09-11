// Package ogsgamesviewer provides details for the OGS Games Viewer applet.
package ogsgamesviewer

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ogs_games_viewer.star
var source []byte

// New creates a new instance of the OGS Games Viewer applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ogs-games-viewer",
		Name:        "OGS Games Viewer",
		Author:      "Neal Wright",
		Summary:     "Shows OGS Games",
		Desc:        "Shows a visualization of currently active Go games on OGS (Online Go Server) for a given user.",
		FileName:    "ogs_games_viewer.star",
		PackageName: "ogsgamesviewer",
		Source:  source,
	}
}
