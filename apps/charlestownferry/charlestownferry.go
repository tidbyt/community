// Package charlestownferry provides details for the CharlestownFerry applet.
package charlestownferry

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed charlestownferry.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the CharlestownFerry applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "charlestownferry",
		Name:        "CharlestownFerry",
		Author:      "jblaker",
		Summary:     "Ferry Depature Times",
		Desc:        "Displays three upcoming ferry depature times for the Charlestown, MA Ferry.",
		FileName:    "charlestownferry.star",
		PackageName: "charlestownferry",
		Source:      source,
	}
}
