// Package countupclock provides clock time since an event.
package countupclock

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed countupclock.star
var source []byte

// New creates instance of applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "countupclock",
		Name:        "Count Up Clock",
		Author:      "jvivona",
		Summary:     "Clock time since an event",
		Desc:        "Shows elapsed time in days, hours and minutes since an event with custom title.",
		FileName:    "countupclock.star",
		PackageName: "countupclock",
		Source:      source,
	}
}