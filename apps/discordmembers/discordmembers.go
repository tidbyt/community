// Package discordmembers provides details for the Discord Members applet.
package discordmembers

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed discordmembers.star
var source []byte

// New creates a new instance of the Discord Members applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "discordmembers",
		Name:        "Discord Members",
		Author:      "Dennis Zoma (https://zoma.dev)",
		Summary:     "Discord Members Count",
		Desc:        "Display the approximate member count for a given Discord server (via Invite ID).",
		FileName:    "discordmembers.star",
		PackageName: "discordmembers",
		Source:  source,
	}
}
