// Package gapilotbuddy provides details for the GA Pilot Buddy applet.
package gapilotbuddy

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed ga_pilot_buddy.star
var source []byte

// New creates a new instance of the GA Pilot Buddy applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "ga-pilot-buddy",
		Name:        "GA Pilot Buddy",
		Author:      "icdevin",
		Summary:     "Local flight rules and wx",
		Desc:        "See local aerodrome flight rules and current abbreviated METAR information.",
		FileName:    "ga_pilot_buddy.star",
		PackageName: "gapilotbuddy",
		Source:  source,
	}
}
