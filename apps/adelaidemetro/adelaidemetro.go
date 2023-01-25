// Package adelaidemetro provides details for the Adelaide Metro applet.
package adelaidemetro

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed adelaide_metro.star
var source []byte

// New creates a new instance of the Adelaide Metro applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "adelaide-metro",
		Name:        "Adelaide Metro",
		Author:      "M0ntyP",
		Summary:     "Next arrivals in ADL",
		Desc:        "Displays upcoming services for train stations and bus & tram stops around Adelaide.",
		FileName:    "adelaide_metro.star",
		PackageName: "adelaidemetro",
		Source:  source,
	}
}
