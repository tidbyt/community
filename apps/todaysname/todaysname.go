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
		ID:          "swedish-todays-name",
		Name:        "Swedish Today's Name",
		Author:      "y34752",
		Summary:     "Shows todays name in Sweden",
		Desc:        "The app shows today's name day names in Sweden.",
		FileName:    "todays_name.star",
		PackageName: "todaysname",
		Source:  source,
	}
}
