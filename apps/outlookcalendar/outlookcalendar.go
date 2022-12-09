// Package outlookcalendar provides details for the Outlook Calendar applet.
package outlookcalendar

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed outlook_calendar.star
var source []byte

// New creates a new instance of the Outlook Calendar applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "outlook-calendar",
		Name:        "Outlook Calendar",
		Author:      "Matt-Pesce",
		Summary:     "Display Next Meeting",
		Desc:        "Shows the date, next meeting and time from your Outlook Calendar.",
		FileName:    "outlook_calendar.star",
		PackageName: "outlookcalendar",
		Source:  source,
	}
}
