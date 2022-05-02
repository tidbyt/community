// Package goodservice provides details for the Goodservice applet.
package goodservice

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed goodservice.star
var source []byte

// New creates a new instance of the Goodservice applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "goodservice",
		Name:        "Goodservice",
		Author:      "blahblahblah-",
		Summary:     "Goodservice NYC subway",
		Desc:        "Projected New York City subway departure times, powered by goodservice.io.",
		FileName:    "goodservice.star",
		PackageName: "goodservice",
		Source:  source,
	}
}
