// Package moretransit provides details for the MoreTransit applet.
package moretransit

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed moretransit.star
var source []byte

// New creates a new instance of the MoreTransit applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "moretransit",
		Name:        "MoreTransit",
		Author:      "gdcolella",
		Summary:     "See next transit arrivals",
		Desc:        "See next transit arrivals from TransSee. Optimized for NYC Subway and more customizable than the default apps.",
		FileName:    "moretransit.star",
		PackageName: "moretransit",
		Source:  source,
	}
}
