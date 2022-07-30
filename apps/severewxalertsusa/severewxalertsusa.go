// Package severewxalertsusa provides details for the SevereWxAlertsUSA applet.
package severewxalertsusa

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed severewxalertsusa.star
var source []byte

// New creates a new instance of the SevereWxAlertsUSA applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "severewxalertsusa",
		Name:        "SevereWxAlertsUSA",
		Author:      "aschechter88",
		Summary:     "Display US Severe Wx Alerts",
		Desc:        "Show Severe Weather Alerts in your location issued by the US National Weather Service.",
		FileName:    "severewxalertsusa.star",
		PackageName: "severewxalertsusa",
		Source:  source,
	}
}
