// Package flags provides details for the Flags applet.
package flags

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed flags.star
var source []byte

// New creates a new instance of the Flags applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "flags",
		Name:        "Flags",
		Author:      "btjones",
		Summary:     "Displays a country flag",
		Desc:        "Displays a random or specific country flag.",
		FileName:    "flags.star",
		PackageName: "flags",
		Source:  source,
	}
}
