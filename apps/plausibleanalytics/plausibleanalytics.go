// Package plausiblestats provides details for the Plausible Stats applet.
package plausibleanalytics

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed plausibleanalytics.star
var source []byte

// New creates a new instance of the Plausible Stats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "plausible-analytics",
		Name:        "Plausible Stats",
		Author:      "brettohland",
		Summary:     "Plausible Analytics Display",
		Desc:        "Display your website's traffic stats using your Plausible Analytics account.",
		FileName:    "plausibleanalytics.star",
		PackageName: "plausibleanalytics",
		Source:  source,
	}
}
