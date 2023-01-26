// Package guardiannews provides details for the Guardian News applet.
package guardiannews

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed guardian_news.star
var source []byte

// New creates a new instance of the Guardian News applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "guardian-news",
		Name:        "Guardian News",
		Author:      "meejle",
		Summary:     "Latest news",
		Desc:        "Show the latest Guardian top story from your preferred Edition.",
		FileName:    "guardian_news.star",
		PackageName: "guardiannews",
		Source:  source,
	}
}
