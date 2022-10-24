// Package desknametag provides details for the Desk Name Tag applet.
package desknametag

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed desk_name_tag.star
var source []byte

// New creates a new instance of the Desk Name Tag applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "desk-name-tag",
		Name:        "Desk Name Tag",
		Author:      "Brian Bell",
		Summary:     "Tell coworkers about you",
		Desc:        "Displays basic employee information to coworkers.",
		FileName:    "desk_name_tag.star",
		PackageName: "desknametag",
		Source:  source,
	}
}
