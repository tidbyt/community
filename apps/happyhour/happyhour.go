// Package happyhour provides details for the Happy Hour applet.
package happyhour

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed happy_hour.star
var source []byte

// New creates a new instance of the Happy Hour applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "happy-hour",
		Name:        "Happy Hour",
		Author:      "Nicole Brooks",
		Summary:     "Hourly Cocktail Generator",
		Desc:        "Displays a new cocktail every hour, on the hour. Cheers to my mom for the color scheme, idea, AND name!",
		FileName:    "happy_hour.star",
		PackageName: "happyhour",
		Source:  source,
	}
}
