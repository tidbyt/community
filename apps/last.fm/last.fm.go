// Package last.fm provides details for the Last.fm applet.
package last.fm

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed last.fm.star
var source []byte

// New creates a new instance of the Last.fm applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "last.fm",
		Name:        "Last.fm",
		Author:      "mattygroch",
		Summary:     "Show Last.fm's Now Playing",
		Desc:        "An app to display whatever song you're currently scrobbling to your Last.fm profile.",
		FileName:    "last.fm.star",
		PackageName: "last.fm",
		Source:  source,
	}
}
