// Package severewxalertsusa provides details for the SevereWxAlertsUsa applet.
package severewxalertsusa

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed severewxalertsusa.star
var source []byte

// New creates a new instance of the SevereWxAlertsUsa applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "severewxalertsusa",
		Name:        "SevereWxAlertsUsa",
		Author:      "lawnchairs",
		Summary:     "Shows US Weather Alerts",
		Desc:        "Displays the headlines for severe weather alerts for your location issued by the US National Weather Service.",
		FileName:    "severewxalertsusa.star",
		PackageName: "severewxalertsusa",
		Source:  source,
	}
}
