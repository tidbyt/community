// Package officestatus provides details for the Office Status applet.
package officestatus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed office_status.star
var source []byte

// New creates a new instance of the Office Status applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "office-status",
		Name:        "Office Status",
		Author:      "Brian Bell",
		Summary:     "Show coworkers your status",
		Desc:        "Show coworkers whether you're free, busy, remote, or away.",
		FileName:    "office_status.star",
		PackageName: "officestatus",
		Source:      source,
	}
}
