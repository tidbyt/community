// Package todaysname provides details for the Todays Name applet.
package todaysname

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed todays_name.star
var source []byte

// New creates a new instance of the Todays Name applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "todays-name",
		Name:        "Todays Name",
		Author:      "Ylva Strandell",
		Summary:     "Shows todays name in Sweden",
		Desc:        "The app shows todays nameday names in SWeden.",
		FileName:    "todays_name.star",
		PackageName: "todaysname",
		Source:  source,
	}
}
