// Package wordoftheday provides details for the Word Of The Day applet.
package wordoftheday

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed word_of_the_day.star
var source []byte

// New creates a new instance of the Word Of The Day applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "word-of-the-day",
		Name:        "Word Of The Day",
		Author:      "greg-n",
		Summary:     "Shows the Word Of The Day",
		Desc:        "Displays the Merriam-Webster Word Of The Day.",
		FileName:    "word_of_the_day.star",
		PackageName: "wordoftheday",
		Source:  source,
	}
}
