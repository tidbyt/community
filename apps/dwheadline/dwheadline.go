// Package dwheadline provides details for the DW Headline applet.
package dwheadline

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed dw_headline.star
var source []byte

// New creates a new instance of the DW Headline applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "dw-headline",
		Name:        "DW Headline",
		Author:      "bmdelaune",
		Summary:     "DailyWire Headlines",
		Desc:        "Shows the latest published headline on DailyWire.com.",
		FileName:    "dw_headline.star",
		PackageName: "dwheadline",
		Source:  source,
	}
}
