// Package tvquotes provides details for the TV Quotes applet.
package tvquotes

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed tv_quotes.star
var source []byte

// New creates a new instance of the TV Quotes applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "tv-quotes",
		Name:        "TV Quotes",
		Author:      "rs7q5",
		Summary:     "Display Television Quotes",
		Desc:        "Displays Television Quotes.",
		FileName:    "tv_quotes.star",
		PackageName: "tvquotes",
		Source:  source,
	}
}
