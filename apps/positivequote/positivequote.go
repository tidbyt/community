// Package positivequote provides details for the Positive Quote applet.
package positivequote

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed positive_quote.star
var source []byte

// New creates a new instance of the Positive Quote applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "positive-quote",
		Name:        "Positive Quote",
		Author:      "Brian Bell",
		Summary:     "Display a positive quote",
		Desc:        "Shows the user a random positive quote.",
		FileName:    "positive_quote.star",
		PackageName: "positivequote",
		Source:  source,
	}
}
