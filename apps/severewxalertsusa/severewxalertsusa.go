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
		Author:      "aschechter88",
		Summary:     "USA Severe WX Alerts",
		Desc:        "Display count and contents of Severe Weather Alerts issued by the US National Weather Service for your location.",
		FileName:    "severewxalertsusa.star",
		PackageName: "severewxalertsusa",
		Source:  source,
	}
}
