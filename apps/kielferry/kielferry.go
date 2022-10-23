// Package kielferry provides details for the Kiel Ferry applet.
package kielferry

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed kiel_ferry.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Kiel Ferry applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "kiel-ferry",
		Name:        "Kiel Ferry",
		Author:      "hloeding",
		Summary:     "Kiel Ferry Departures",
		Desc:        "Next scheduled ferry departure time for any stop and direction in the Kiel harbor ferry system.",
		FileName:    "kiel_ferry.star",
		PackageName: "kielferry",
		Source:      source,
	}
}
