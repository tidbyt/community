// Package cltlightrail provides details for the CLT Lightrail applet.
package cltlightrail

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed clt_lightrail.star
var source []byte

// New creates a new instance of the CLT Lightrail applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "clt-lightrail",
		Name:        "CLT Lightrail",
		Author:      "Kevin Connell",
		Summary:     "Tracks CLT Lightrail Trains",
		Desc:        "Displays in real-time when North & South lightrail trains will arrive in Charlotte's LYNX Lightrail System - All Stations available.",
		FileName:    "clt_lightrail.star",
		PackageName: "cltlightrail",
		Source:  source,
	}
}
