// Package pagerduty provides details for the PagerDuty applet.
package pagerduty

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pagerduty.star
var source []byte

// New creates a new instance of the PagerDuty applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "pagerduty",
		Name:        "PagerDuty",
		Author:      "Nick Penree",
		Summary:     "Show PagerDuty stats",
		Desc:        "Show PagerDuty incident stats and on-call status.",
		FileName:    "pagerduty.star",
		PackageName: "pagerduty",
		Source:  source,
	}
}
