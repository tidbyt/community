// Package snyk provides details for the Snyk applet.
package snyk

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed snyk.star
var source []byte

// New creates a new instance of the Snyk applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "snyk",
		Name:        "Snyk",
		Author:      "Andrew Powell",
		Summary:     "Snyk project issue counts",
		Desc:        "Shows medium/high/critical issue counts for the configured Snyk project.",
		FileName:    "snyk.star",
		PackageName: "snyk",
		Source:  source,
	}
}
