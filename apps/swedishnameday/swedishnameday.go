// Package swedishnameday provides details for the Swedish Name Day applet.
package swedishnameday

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed swedish_name_day.star
var source []byte

// New creates a new instance of the Todays Name applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "swedish-name-day",
		Name:        "Swedish Name Day",
		Author:      "y34752",
		Summary:     "Today's name in Sweden",
		Desc:        "Shows today's name day names in Sweden.",
		FileName:    "swedish_name_day.star",
		PackageName: "swedishnameday",
		Source:      source,
	}
}
