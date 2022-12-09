// Package mastodoncounter provides details for the Mastodon Counter applet.
package mastodoncounter

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mastodon_counter.star
var source []byte

// New creates a new instance of the Mastodon Counter applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mastodon-counter",
		Name:        "Mastodon Counter",
		Author:      "meejle",
		Summary:     "Shows your follower count",
		Desc:        "Shows how many followers you've got on Mastodon. If you want, it can even promote your Mastodon handle and encourage people to follow you.",
		FileName:    "mastodon_counter.star",
		PackageName: "mastodoncounter",
		Source:  source,
	}
}
