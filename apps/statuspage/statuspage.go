// Package statuspage provides details for the StatusPage applet.
package statuspage

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed statuspage.star
var source []byte

// New creates a new instance of the StatusPage applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "statuspage",
		Name:        "StatusPage",
		Author:      "Ricky Smith (DigitallyBorn)",
		Summary:     "A statuspage status",
		Desc:        "Shows the status of a page from StatusPage.io.",
		FileName:    "statuspage.star",
		PackageName: "statuspage",
		Source:  source,
	}
}
