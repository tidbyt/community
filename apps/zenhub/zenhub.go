// Package zenhub provides details for the Zenhub applet.
package zenhub

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed zenhub.star
var source []byte

// New creates a new instance of the Zenhub applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "zenhub",
		Name:        "Zenhub",
		Author:      "thiagobrez",
		Summary:     "Show Zenhub issues",
		Desc:        "Show Zenhub issues from a Pipeline of your choice. Filter by labels and assignees.",
		FileName:    "zenhub.star",
		PackageName: "zenhub",
		Source:  source,
	}
}
