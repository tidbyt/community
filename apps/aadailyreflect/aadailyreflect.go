// Package aadailyreflect displays the AA Daily Reflection for today from the website.
package aadailyreflect

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed aadailyreflect.star
var source []byte

// New creates instance of applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "aadailyreflect",
		Name:        "AA Daily Reflect",
		Author:      "jvivona",
		Summary:     "Daily reflection from AA",
		Desc:        "Shows todays daily reflection title, summary and reference from aa.org/daily-reflections.",
		FileName:    "aadailyreflect.star",
		PackageName: "aadailyreflect",
		Source:      source,
	}
}