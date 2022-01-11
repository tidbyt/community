// Package theysaidso provides details for the They Said So applet.
package theysaidso

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed they_said_so.star
var source []byte

// New creates a new instance of the They Said So applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "they-said-so",
		Name:        "They Said So",
		Author:      "Henry So, Jr.",
		Summary:     "Quote of the Day",
		Desc:        "Quote of the day powered by theysaidso.com.",
		FileName:    "they_said_so.star",
		PackageName: "theysaidso",
		Source:  source,
	}
}
