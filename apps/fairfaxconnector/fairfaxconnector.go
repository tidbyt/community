// Package fairfaxconnector provides details for the Fairfax Connector applet.
package fairfaxconnector

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed fairfax_connector.star
var source []byte

// New creates a new instance of the Fairfax Connector applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "fairfax-connector",
		Name:        "Fairfax Connector",
		Author:      "Austin Pearce",
		Summary:     "Connector bus stop info",
		Desc:        "Shows when your next bus is arriving. Visit fairfaxconnector.com for more information.",
		FileName:    "fairfax_connector.star",
		PackageName: "fairfaxconnector",
		Source:  source,
	}
}
