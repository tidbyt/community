// Package dailyreminder provides details for the Daily Reminder applet.
package dailyreminder

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed daily_reminder.star
var source []byte

// New creates a new instance of the Daily Reminder applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "daily-reminder",
		Name:        "Daily Reminder",
		Author:      "sepowitz",
		Summary:     "A daily reminder app",
		Desc:        "Set a reminder for each day of week.",
		FileName:    "daily_reminder.star",
		PackageName: "dailyreminder",
		Source:  source,
	}
}
