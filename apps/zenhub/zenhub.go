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
		Summary:     "Displays Zenhub issues",
		Desc:        "Displays your last 3 Zenhub issues from the chosen pipeline, and filter by labels and assignees. To generate your API Keys, visit https://app.zenhub.com/settings/tokens. To retrieve your Workspace and Repository IDs, see https://github.com/ZenHubIO/API#endpoint-reference.",
		FileName:    "zenhub.star",
		PackageName: "zenhub",
		Source:  source,
	}
}
