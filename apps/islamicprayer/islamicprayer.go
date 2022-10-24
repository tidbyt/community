// Package islamicprayer provides details for the Islamic Prayer applet.
package islamicprayer

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed islamic_prayer.star
var source []byte

// New creates a new instance of the Islamic Prayer applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "islamic-prayer",
		Name:        "Islamic Prayer",
		Author:      "Austin Fonacier",
		Summary:     "Islamic prayer times",
		Desc:        "Islamic prayer times for the day.",
		FileName:    "islamic_prayer.star",
		PackageName: "islamicprayer",
		Source:  source,
	}
}
