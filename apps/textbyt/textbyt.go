// Package textbyt provides details for the Textbyt applet.
package textbyt

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed textbyt.star
var source []byte

// New creates a new instance of the Textbyt applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "textbyt",
		Name:        "Textbyt",
		Author:      "Josh Reed",
		Summary:     "Display text messages",
		Desc:        "Display a scrolling message sent in via text.",
		FileName:    "textbyt.star",
		PackageName: "textbyt",
		Source:  source,
	}
}
