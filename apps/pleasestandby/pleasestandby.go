// Package pleasestandby provides details for the Please Stand By applet.
package pleasestandby

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed please_stand_by.star
var source []byte

// New creates a new instance of the Please Stand By applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "please-stand-by",
		Name:        "Please Stand By",
		Author:      "Ethan Fuerst (@ethanfuerst)",
		Summary:     "Displays Please Stand By",
		Desc:        "Displays Please Stand By message.",
		FileName:    "please_stand_by.star",
		PackageName: "pleasestandby",
		Source:  source,
	}
}
