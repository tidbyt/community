// Package skireport provides details for the Ski Report applet.
package skireport

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ski_report.star
var source []byte

// New creates a new instance of the Ski Report applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ski-report",
		Name:        "Ski Report",
		Author:      "Colin Morrisseau",
		Summary:     "Weather and Trails",
		Desc:        "Weather and Trail status for Mountains that are part of the Epic Pass resort system.",
		FileName:    "ski_report.star",
		PackageName: "skireport",
		Source:  source,
	}
}
