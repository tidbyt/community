// Package twitch provides details for the Twitch applet.
package twitch

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed twitch.star
var source []byte

// New creates a new instance of the Twitch applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "twitch",
		Name:        "Twitch",
		Author:      "Nick Penree",
		Summary:     "Display info from Twitch",
		Desc:        "Display info for a Twitch username.",
		FileName:    "twitch.star",
		PackageName: "twitch",
		Source:  source,
	}
}
