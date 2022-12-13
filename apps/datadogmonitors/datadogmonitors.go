// Package datadogmonitors provides details for the DataDog Monitors applet.
package datadogmonitors

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed datadog_monitors.star
var source []byte

// New creates a new instance of the DataDog Monitors applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "datadog-monitors",
		Name:        "DataDog Monitors",
		Author:      "Cavallando",
		Summary:     "View your DataDog Monitors",
		Desc:        "By default displays any monitors that are in the status alert but allows for customizing the query yourself based on DataDog's syntax.",
		FileName:    "datadog_monitors.star",
		PackageName: "datadogmonitors",
		Source:  source,
	}
}
