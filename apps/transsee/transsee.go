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
		Author:      "Darwin O'Connor",
		Summary:     "Realtime transit prediction",
		Desc:        "Provides real-time transit predictions based on actual travel times. Requires paid premium. See transsee.ca/tidbyt for usage information",
		FileName:    "transsee.star",
		PackageName: "transsee",
		Source:  source,
	}
}
