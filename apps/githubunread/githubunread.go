// Package githubunread provides details for the Github Unread applet.
package githubunread

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed github_unread.star
var source []byte

// New creates a new instance of the Github Unread applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "github-unread",
		Name:        "GitHub Unread",
		Author:      "ElliottAYoung",
		Summary:     "GitHub notification count",
		Desc:        "Displays the count of unread GitHub notifications",
		FileName:    "github_unread.star",
		PackageName: "githubunread",
		Source:      source,
	}
}