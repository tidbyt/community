// Package chicagodivvy provides details for the Chicago Divvy applet.
package chicagodivvy

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed chicago_divvy.star
var source []byte

// New creates a new instance of the Chicago Divvy applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "chicago-divvy",
		Name:        "Chicago Divvy",
		Author:      "Will Kelly",
		Summary:     "Chicago Divvy Bikes",
		Desc:        "Displays the number of Divvy bikes available at a Divvy station.",
		FileName:    "chicago_divvy.star",
		PackageName: "chicagodivvy",
		Source:      source,
	}
}
