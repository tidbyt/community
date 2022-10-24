// Package dateprogress provides details for the Date Progress applet.
package dateprogress

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed date_progress.star
var source []byte

// New creates a new instance of the Date Progress applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "date-progress",
		Name:        "Date Progress",
		Author:      "possan",
		Summary:     "Shows date as percentages",
		Desc:        "Shows todays date as colorful progressbars, you can show the progress of the current day, month and year.",
		FileName:    "date_progress.star",
		PackageName: "dateprogress",
		Source:  source,
	}
}
