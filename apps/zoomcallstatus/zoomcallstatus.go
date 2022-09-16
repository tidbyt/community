// Package zoomcallstatus provides details for the Zoom Call Status applet.
package zoomcallstatus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed zoom_call_status.star
var source []byte

// New creates a new instance of the Zoom Call Status applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "zoom-call-status",
		Name:        "Zoom Call Status",
		Author:      "CFitzsimons",
		Summary:     "Show zoom call status",
		Desc:        "Displays a live status based on whether the user is in a call or on Do Not Disturb. Please create a JWT based Zoom app (on the Zoom site) and add it in the settings to get started.",
		FileName:    "zoom_call_status.star",
		PackageName: "zoomcallstatus",
		Source:  source,
	}
}
