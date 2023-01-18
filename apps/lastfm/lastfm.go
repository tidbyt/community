// Package last.fm provides details for the Last.fm applet.
package lastfm

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed last.fm.star
var source []byte

// New creates a new instance of the Last.fm applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "lastfm",
		Name:        "Lastfm",
		Author:      "mattygroch",
		Summary:     "Show Last.fm's Now Playing",
		Desc:        "An app to display whatever song you're currently scrobbling to your Last.fm profile.",
		FileName:    "lastfm.star",
		PackageName: "lastfm",
		Source:  source,
	}
}
