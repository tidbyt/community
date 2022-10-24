// Package nycbus provides details for the NYC Bus applet.
package nycbus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nyc_bus.star
var source []byte

// New creates a new instance of the NYC Bus applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nyc-bus",
		Name:        "NYC Bus",
		Author:      "samandmoore",
		Summary:     "NYC Bus departures",
		Desc:        "Real time bus departures for your preferred stop.",
		FileName:    "nyc_bus.star",
		PackageName: "nycbus",
		Source:      source,
	}
}
