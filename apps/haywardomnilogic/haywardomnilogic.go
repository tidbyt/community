// Package haywardomnilogic provides details for the Hayward Omnilogic applet.
package haywardomnilogic

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed hayward_omnilogic.star
var source []byte

// New creates a new instance of the Hayward Omnilogic applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "hayward-omnilogic",
		Name:        "Hayward Omnilogic",
		Author:      "kcharwood",
		Summary:     "Display pool temperature",
		Desc:        "Reads pool temperature from Hayward Omnilogic Controller and displays on the Tidbyt.",
		FileName:    "hayward_omnilogic.star",
		PackageName: "haywardomnilogic",
		Source:  source,
	}
}
