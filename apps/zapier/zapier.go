// Package zapier provides details for the Zapier applet.
package zapier

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed zapier.star
var source []byte

// New creates a new instance of the Zapier applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "zapier",
		Name:        "Zapier",
		Author:      "Tidbyt",
		Summary:     "Integrate with Zapier",
		Desc:        "The Zapier app allows you to trigger information on your Tidbyt from a Zap.",
		FileName:    "zapier.star",
		PackageName: "zapier",
		Source:      source,
	}
}
