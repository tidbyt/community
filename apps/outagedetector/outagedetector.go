// Package outagedetector provides details for the Outage Detector applet.
package outagedetector

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed outage_detector.star
var source []byte

// New creates a new instance of the Outage Detector applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "outage-detector",
		Name:        "Outage Detector",
		Author:      "joevgreathead",
		Summary:     "Checks for web page outages",
		Desc:        "Loads a page of your choice to see if it loads ok or is down.",
		FileName:    "outage_detector.star",
		PackageName: "outagedetector",
		Source:  source,
	}
}
