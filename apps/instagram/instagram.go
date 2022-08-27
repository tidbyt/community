// Package instagram provides details for the Instagram applet.
package instagram

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed instagram.star
var source []byte

// New creates a new instance of the Instagram applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "instagram",
		Name:        "Instagram",
		Author:      "Bruce Wayne",
		Summary:     "Instagram follower count",
		Desc:        "Show your Instagram follower count.",
		FileName:    "instagram.star",
		PackageName: "instagram",
		Source:      source,
	}
}
