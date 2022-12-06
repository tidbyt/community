// Package githubstargazers provides details for the GitHub Stargazers applet.
package githubstargazers

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed github_stargazers.star
var source []byte

// New creates a new instance of the GitHub Stargazers applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "github-stargazers",
		Name:        "GitHub Stargazers",
		Author:      "fulghum",
		Summary:     "Display GitHub repo stars",
		Desc:        "Display the GitHub stargazer count for a repo.",
		FileName:    "github_stargazers.star",
		PackageName: "githubstargazers",
		Source:  source,
	}
}
