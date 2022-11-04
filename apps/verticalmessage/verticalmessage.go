// Package verticalmessage provides details for the Vertical Message applet.
package verticalmessage

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed vertical_message.star
var source []byte

// New creates a new instance of the Vertical Message applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "vertical-message",
		Name:        "Vertical Message",
		Author:      "rs7q5",
		Summary:     "Display messages vertically",
		Desc:        "Display a message vertically.",
		FileName:    "vertical_message.star",
		PackageName: "verticalmessage",
		Source:  source,
	}
}
