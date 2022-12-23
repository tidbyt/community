// Package costcogas provides details for the Costco Gas applet.
package costcogas

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed costco_gas.star
var source []byte

// New creates a new instance of the Costco Gas applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "costco-gas",
		Name:        "Costco Gas",
		Author:      "Dan Adam",
		Summary:     "Costco Gas Display",
		Desc:        "Displays gas prices from a selected Costco warehouse in the US.",
		FileName:    "costco_gas.star",
		PackageName: "costcogas",
		Source:      source,
	}
}
