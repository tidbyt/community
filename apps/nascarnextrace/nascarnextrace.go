// Package nascarnextrace provides details for the NASCAR next race applet.
package nascarnextrace

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nascarnextrace.star
var source []byte

// New creates instance of applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nascarnextrace",
		Name:        "NASCAR Next Race",
		Author:      "jvivona",
		Summary:     "Next NASCAR Race",
		Desc:        "Shows time, date and location of next NASCAR race for selected series.",
		FileName:    "nascarnextrace.star",
		PackageName: "nascarnextrace",
		Source:      source,
	}
}
