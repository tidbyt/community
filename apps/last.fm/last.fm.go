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
		Author:      "Chuck Hannah",
		Summary:     "Display Last.fm scrobbles",
		Desc:        "Displays your most recently scrobbled track from Last.fm. Displays Track, Artist, Album Art and an optional clock.",
		FileName:    "last.fm.star",
		PackageName: "last.fm",
		Source:  source,
	}
}
