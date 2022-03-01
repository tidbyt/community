// Package netatmo provides details for the Netatmo applet.
package netatmo

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed netatmo.star
var source []byte

// New creates a new instance of the Netatmo applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "netatmo",
		Name:        "Netatmo",
		Author:      "danmcclain",
		Summary:     "Weather from your Netatmo",
		Desc:        "Get your current weather from your Netatmo weather station.",
		FileName:    "netatmo.star",
		PackageName: "netatmo",
		Source:  source,
	}
}
