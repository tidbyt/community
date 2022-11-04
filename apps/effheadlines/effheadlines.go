// Package effheadlines provides details for the EFF Headlines applet.
package effheadlines

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed effheadlines.star
var source []byte

// New creates a new instance of the EFF Headlines applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "effheadlines",
		Name:        "EFF Headlines",
		Author:      "hainish",
		Summary:     "EFF Headlines tidbyt",
		Desc:        "Get the latest headlines from the Electronic Frontier Foundation.",
		FileName:    "effheadlines.star",
		PackageName: "effheadlines",
		Source:  source,
	}
}
