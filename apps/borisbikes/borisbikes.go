// Package borisbikes provides details for the Boris Bikes applet.
package borisbikes

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed boris_bikes.star
var source []byte

// New creates a new instance of the Boris Bikes applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "boris-bikes",
		Name:        "Boris Bikes",
		Author:      "dinosaursrarr",
		Summary:     "London street bikes",
		Desc:        "Availability for a Santander bicycle dock in London.",
		FileName:    "boris_bikes.star",
		PackageName: "borisbikes",
		Source:  source,
	}
}
