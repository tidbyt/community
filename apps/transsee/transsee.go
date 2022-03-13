// Package transsee provides details for the TransSee applet.
package transsee

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed transsee.star
var source []byte

// New creates a new instance of the TransSee applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "transsee",
		Name:        "TransSee",
		Author:      "doconno@gmail.com",
		Summary:     "Realtime transit prediction",
		Desc:        "Provides real-time transit predictions based on actual travel times for over 150 agencies. Requires paid premium. See transsee.ca/tidbyt for usage information.",
		FileName:    "transsee.star",
		PackageName: "transsee",
		Source:  source,
	}
}
