// Package ctaltracker provides details for the CTA "L" Tracker applet.
package ctaltracker

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed cta_l_tracker.star
var source []byte

// New creates a new instance of the CTA "L" Tracker applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "cta-l-tracker",
		Name:        "CTA \"L\" Tracker",
		Author:      "samshapiro13",
		Summary:     "Shows CTA \"L\" arrivals",
		Desc:        "Shows the next two arriving CTA \"L\" Trains for a selected station.",
		FileName:    "cta_l_tracker.star",
		PackageName: "ctaltracker",
		Source:  source,
	}
}
