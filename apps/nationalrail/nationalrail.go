// Package nationalrail provides details for the National Rail applet.
package nationalrail

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed national_rail.star
var source []byte

// New creates a new instance of the National Rail applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "national-rail",
		Name:        "National Rail",
		Author:      "dinosaursrarr",
		Summary:     "Live UK train departures",
		Desc:        "Realtime departure board information from National Rail Enquiries.",
		FileName:    "national_rail.star",
		PackageName: "nationalrail",
		Source:  source,
	}
}
