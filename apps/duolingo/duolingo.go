// Package duolingo provides details for the Duolingo applet.
package duolingo

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed duolingo.star
var source []byte

// New creates a new instance of the Duolingo applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "duolingo",
		Name:        "Duolingo",
		Author:      "Olly Stedall @saltedlolly",
		Summary:     "Display Duolingo Progress",
		Desc:        "Track your Duolingo study progress. The app has multiple views: Today, Week, Two Weeks. You can add multiple instances to display more than one. Note: The app will be hidden from the rotation if no lessons have been completed in the last week.",
		FileName:    "duolingo.star",
		PackageName: "duolingo",
		Source:  source,
	}
}
