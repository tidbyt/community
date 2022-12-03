// Package carenewables provides details for the CA Renewables applet.
package carenewables

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ca_renewables.star
var source []byte

// New creates a new instance of the CA Renewables applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ca-renewables",
		Name:        "CA Renewables",
		Author:      "sloanesturz",
		Summary:     "Track CA's power grid",
		Desc:        "See how California is using renewable energy in its power grid right now.",
		FileName:    "ca_renewables.star",
		PackageName: "carenewables",
		Source:      source,
	}
}
