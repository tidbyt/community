// Package astropicofday provides details for the Astro Pic of Day applet.
package astropicofday

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed astro_pic_of_day.star
var source []byte

// New creates a new instance of the Astro Pic of Day applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "astro-pic-of-day",
		Name:        "Astro Pic of Day",
		Author:      "Brian Bell",
		Summary:     "New pic from NASA each day",
		Desc:        "Displays the astronomy picture of the day from NASA.",
		FileName:    "astro_pic_of_day.star",
		PackageName: "astropicofday",
		Source:      source,
	}
}
