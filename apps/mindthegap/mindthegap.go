// Package mindthegap provides details for the Mind The Gap applet.
package mindthegap

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mind_the_gap.star
var source []byte

// New creates a new instance of the Mind The Gap applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mind-the-gap",
		Name:        "Mind The Gap",
		Author:      "dinosaursrarr",
		Summary:     "Tube platform simulator",
		Desc:        "Important advice for Londoners to remember at all times.",
		FileName:    "mind_the_gap.star",
		PackageName: "mindthegap",
		Source:  source,
	}
}
