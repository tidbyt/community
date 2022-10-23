// Package ifparank provides details for the IFPARank applet.
package ifparank

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed ifparank.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the IFPARank applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ifparank",
		Name:        "IFPARank",
		Author:      "cubsaaron",
		Summary:     "Display IFPA Ranking",
		Desc:        "Display an International Flipper Pinball Association (IFPA) World Ranking.",
		FileName:    "ifparank.star",
		PackageName: "ifparank",
		Source:      source,
	}
}
