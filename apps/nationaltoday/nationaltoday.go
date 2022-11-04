// Package nationaltoday provides details for the NationalToday applet.
package nationaltoday

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed nationaltoday.star
var source []byte

// New creates a new instance of the NationalToday applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nationaltoday",
		Name:        "NationalToday",
		Author:      "rs7q5",
		Summary:     "Get NationalToday holidays",
		Desc:        "Displays today's holidays from NationalToday.",
		FileName:    "nationaltoday.star",
		PackageName: "nationaltoday",
		Source:  source,
	}
}
