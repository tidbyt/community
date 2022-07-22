// Package wordlebyt provides details for the Wordlebyt applet.
package wordlebyt

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed wordlebyt.star
var source []byte

// New creates a new instance of the Wordlebyt applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "wordlebyt",
		Name:        "Wordlebyt",
		Author:      "skola28",
		Summary:     "Display daily Wordle score",
		Desc:        "After playing Wordle on your phone, click Share>Copy text. In the Tidbyt app, paste the result into Wordlebyt.",
		FileName:    "wordlebyt.star",
		PackageName: "wordlebyt",
		Source:      source,
	}
}
