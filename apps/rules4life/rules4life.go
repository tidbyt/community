// Package rules4life provides details for the Rules4Life applet.
package rules4life

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed rules4life.star
var source []byte

// New creates a new instance of the Rules4Life applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "rules4life",
		Name:        "Rules4Life",
		Author:      "Robert Ison",
		Summary:     "Display Rules for Life",
		Desc:        "Display Jordan B. Peterson's Rules for Life from his book.",
		FileName:    "rules4life.star",
		PackageName: "rules4life",
		Source:  source,
	}
}
