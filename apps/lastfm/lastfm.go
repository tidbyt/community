// Package lastfm provides details for the Last FM applet.
package lastfm

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed last_fm.star
var source []byte

// New creates a new instance of the Last FM applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "last-fm",
		Name:        "Last FM",
		Author:      "Chuck",
		Summary:     "Show Last.fm history",
		Desc:        "Show title, artist and album art from most recently scrobbled song in your Last.fm history.",
		FileName:    "last_fm.star",
		PackageName: "lastfm",
		Source:  source,
	}
}
