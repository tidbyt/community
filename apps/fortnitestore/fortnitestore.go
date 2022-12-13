// Package fortnitestore provides details for the Fortnite Store applet.
package fortnitestore

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed fortnite_store.star
var source []byte

// New creates a new instance of the Fortnite Store applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "fortnite-store",
		Name:        "Fortnite Store",
		Author:      "naominori",
		Summary:     "See the Fortnite shop",
		Desc:        "See items currently featured in the Fortnite shop.",
		FileName:    "fortnite_store.star",
		PackageName: "fortnitestore",
		Source:  source,
	}
}
