// Package trivia provides details for the Trivia applet.
package trivia

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed trivia.star
var source []byte

// New creates a new instance of the Trivia applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "trivia",
		Name:        "Trivia",
		Author:      "Jack Sherbal",
		Summary:     "Random trivia question",
		Desc:        "Displays a random trivia question with category and difficulty.",
		FileName:    "trivia.star",
		PackageName: "trivia",
		Source:  source,
	}
}
