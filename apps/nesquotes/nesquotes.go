// Package nesquotes provides details for the NES Quotes applet.
package nesquotes

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nes_quotes.star
var source []byte

// New creates a new instance of the NES Quotes applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nes-quotes",
		Name:        "NES Quotes",
		Author:      "Mark McIntyre",
		Summary:     "Random NES quotes",
		Desc:        "Displays random quotes from Nintendo Entertainment System games.",
		FileName:    "nes_quotes.star",
		PackageName: "nesquotes",
		Source:  source,
	}
}
