// Package githubrepo provides details for the GitHub Repo applet.
package githubrepo

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed github_repo.star
var source []byte

// New creates a new instance of the GitHub Repo applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "github-repo",
		Name:        "GitHub Repo",
		Author:      "rs7q5",
		Summary:     "Display GitHub repo stats",
		Desc:        "Display various statistics of a public GitHub repo.",
		FileName:    "github_repo.star",
		PackageName: "githubrepo",
		Source:  source,
	}
}
