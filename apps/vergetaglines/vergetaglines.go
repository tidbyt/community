// Package vergetaglines provides details for the Verge Taglines applet.
package vergetaglines

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed verge_taglines.star
var source []byte

// New creates a new instance of the Verge Taglines applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "verge-taglines",
		Name:        "Verge Taglines",
		Author:      "@joevgreathead",
		Summary:     "The Verge's latest tagline",
		Desc:        "Displays the latest tagline from the top of popular tech news site The Verge (dot com).",
		FileName:    "verge_taglines.star",
		PackageName: "vergetaglines",
		Source:  source,
	}
}
