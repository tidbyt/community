// Package lastfm provides details for the Lastfm applet.
package lastfm

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed lastfm.star
var source []byte

// New creates a new instance of the Lastfm applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "lastfm",
		Name:        "Lastfm",
		Author:      "mattygroch",
		Summary:     "What are you scrobbling",
		Desc:        "This app will display whatever track is currently being scrobbled to your Last.fm profile.",
		FileName:    "lastfm.star",
		PackageName: "lastfm",
		Source:  source,
	}
}
