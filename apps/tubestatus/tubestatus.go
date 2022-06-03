// Package tubestatus provides details for the Tube Status applet.
package tubestatus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed tube_status.star
var source []byte

// New creates a new instance of the Tube Status applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "tube-status",
		Name:        "Tube Status",
		Author:      "dinosaursrarr",
		Summary:     "Current status from TfL",
		Desc:        "Shows the current status of each line on London Underground and other TfL services.",
		FileName:    "tube_status.star",
		PackageName: "tubestatus",
		Source:  source,
	}
}
