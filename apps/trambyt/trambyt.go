// Package trambyt provides details for the Trambyt applet.
package trambyt

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed trambyt.star
var source []byte

// New creates a new instance of the Trambyt applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "trambyt",
		Name:        "Trambyt",
		Author:      "protocol7",
		Summary:     "Departures for Västtrafik",
		Desc:        "Show departures for Västtrafik stops.",
		FileName:    "trambyt.star",
		PackageName: "trambyt",
		Source:  source,
	}
}
