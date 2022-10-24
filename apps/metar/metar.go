// Package metar provides details for the METAR applet.
package metar

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed metar.star
var source []byte

// New creates a new instance of the METAR applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "metar",
		Name:        "METAR",
		Author:      "Alexander Valys",
		Summary:     "METAR text and flight rules",
		Desc:        "Show METAR text for one airport or flight category (VFR/IFR/etc.) for up to 15 airports.",
		FileName:    "metar.star",
		PackageName: "metar",
		Source:  source,
	}
}
