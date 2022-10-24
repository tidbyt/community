// Package nhllive provides details for the NHL Live applet.
package nhllive

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nhl_live.star
var source []byte

// New creates a new instance of the NHL Live applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nhl-live",
		Name:        "NHL Live",
		Author:      "Reed Arneson",
		Summary:     "Live updates of NHL games",
		Desc:        "Displays live game stats or next scheduled NHL game information.",
		FileName:    "nhl_live.star",
		PackageName: "nhllive",
		Source:  source,
	}
}
