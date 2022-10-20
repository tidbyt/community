// Package sportsstandings provides details for the Sports Standings applet.
package sportsstandings

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed sports_standings.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Sports Standings applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "sports-standings",
		Name:        "Sports Standings",
		Author:      "rs7q5",
		Summary:     "Get sports standings",
		Desc:        "Get various sports standings (data courtesy of ESPN).",
		FileName:    "sports_standings.star",
		PackageName: "sportsstandings",
		Source:      source,
	}
}
