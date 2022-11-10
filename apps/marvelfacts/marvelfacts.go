// Package marvelfacts provides details for the Marvel Facts applet.
package marvelfacts

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed marvel_facts.star
var source []byte

// New creates a new instance of the Marvel Facts applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "marvel-facts",
		Name:        "Marvel Facts",
		Author:      "Kaitlyn Musial",
		Summary:     "Character Info",
		Desc:        "Gives you the description or number of comics a random character has been in.",
		FileName:    "marvel_facts.star",
		PackageName: "marvelfacts",
		Source:  source,
	}
}
