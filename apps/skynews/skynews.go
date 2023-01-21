// Package skynews provides details for the Sky News applet.
package skynews

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed skynews.star
var source []byte

// New creates a new instance of the Sky News applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "sky-news",
		Name:        "Sky News",
		Author:      "meejle",
		Summary:     "Latest news",
		Desc:        "The current top story (and a short blurb) from SkyNews.com.",
		FileName:    "skynews.star",
		PackageName: "skynews",
		Source:      source,
	}
}
