// Package powerball provides details for the PowerBall applet.
package powerball

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed powerball.star
var source []byte

// New creates a new instance of the PowerBall applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "powerball",
		Name:        "PowerBall",
		Author:      "Amillion Air",
		Summary:     "Shows Powerball Numbers",
		Desc:        "Shows current powerball numbers and next draw date.",
		FileName:    "powerball.star",
		PackageName: "powerball",
		Source:  source,
	}
}
