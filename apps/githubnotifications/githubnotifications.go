// Package githubnotifications provides details for the Github Notifications applet.
package githubnotifications

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed github_notifications.star
var source []byte

// New creates a new instance of the Github Notifications applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "github-notifications",
		Name:        "GitHub Notifications",
		Author:      "ElliottAYoung",
		Summary:     "GitHub notification count",
		Desc:        "Displays the count of unread GitHub notifications",
		FileName:    "github_notifications.star",
		PackageName: "githubnotifications",
		Source:      source,
	}
}