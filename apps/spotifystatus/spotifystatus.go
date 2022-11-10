// Package spotifystatus provides details for the Spotify Status applet.
package spotifystatus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed spotify_status.star
var source []byte

// New creates a new instance of the Spotify Status applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "spotify-status",
		Name:        "Spotify Status",
		Author:      "Kaitlyn Musial",
		Summary:     "Now Playing",
		Desc:        "Connects to Spotify API to display currently playing status.",
		FileName:    "spotify_status.star",
		PackageName: "spotifystatus",
		Source:  source,
	}
}
