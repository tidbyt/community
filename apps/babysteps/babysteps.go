// Package babysteps provides details for the Baby Steps applet.
package babysteps

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed baby_steps.star
var source []byte

// New creates a new instance of the Baby Steps applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "baby-steps",
		Name:        "Baby Steps",
		Author:      "Robert Ison",
		Summary:     "Financial Baby Steps",
		Desc:        "Tracks your baby steps to financial freedom.",
		FileName:    "baby_steps.star",
		PackageName: "babysteps",
		Source:  source,
	}
}
