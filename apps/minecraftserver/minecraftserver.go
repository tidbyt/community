// Package minecraftserver provides details for the Minecraft Server applet.
package minecraftserver

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed minecraft_server.star
var source []byte

// New creates a new instance of the Minecraft Server applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "minecraft-server",
		Name:        "Minecraft Server",
		Author:      "Michael Blades",
		Summary:     "Minecraft Server Activity",
		Desc:        "View Minecraft Server Activity and icon.",
		FileName:    "minecraft_server.star",
		PackageName: "minecraftserver",
		Source:  source,
	}
}
