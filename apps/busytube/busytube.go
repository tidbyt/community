// Package busytube provides details for the Busy Tube applet.
package busytube

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed busy_tube.star
var source []byte

// New creates a new instance of the Busy Tube applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "busy-tube",
		Name:        "Busy Tube",
		Author:      "dinosaursrarr",
		Summary:     "London station crowding",
		Desc:        "Tells you how busy a given TfL-operated station in London currently is. Data updated every five minutes.",
		FileName:    "busy_tube.star",
		PackageName: "busytube",
		Source:  source,
	}
}
