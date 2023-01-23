// Package mastodonfollows provides details for the Mastodon Follows applet.
package mastodonfollows

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mastodon_follows.star
var source []byte

// New creates a new instance of the Mastodon Follows applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mastodon-follows",
		Name:        "Mastodon Follows",
		Author:      "Nick Penree",
		Summary:     "Display your follower count",
		Desc:        "Display your follower count from a Mastodon instance.",
		FileName:    "mastodon_follows.star",
		PackageName: "mastodonfollows",
		Source:  source,
	}
}
