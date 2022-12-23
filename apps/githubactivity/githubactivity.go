// Package githubactivity provides details for the GitHub Activity applet.
package githubactivity

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed github_activity.star
var source []byte

// New creates a new instance of the GitHub Activity applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "github-activity",
		Name:        "GitHub Activity",
		Author:      "rs7q5",
		Summary:     "See your GitHub activity",
		Desc:        "Display the last 13 weeks of your GitHub contribution graph in addition to other metrics on your GitHub profile.",
		FileName:    "github_activity.star",
		PackageName: "githubactivity",
		Source:  source,
	}
}
