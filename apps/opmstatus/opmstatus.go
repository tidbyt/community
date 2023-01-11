// Package opmstatus provides details for the OPM Status applet.
package opmstatus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed opm_status.star
var source []byte

// New creates a new instance of the OPM Status applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "opm-status",
		Name:        "OPM Status",
		Author:      "AdamMoses-GitHub",
		Summary:     "Displays current OPM status",
		Desc:        "Displays the current Office of Personnel Management status, which is used by federal employees to know if the normal working conditions have been changed by inclement weather, health hazards, or other alerts. Updates every 2 hours.",
		FileName:    "opm_status.star",
		PackageName: "opmstatus",
		Source:  source,
	}
}
