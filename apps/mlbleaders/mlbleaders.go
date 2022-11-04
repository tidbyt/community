// Package mlbleaders provides details for the MLB Leaders applet.
package mlbleaders

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed mlb_leaders.star
var source []byte

// New creates a new instance of the MLB Leaders applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "mlb-leaders",
		Name:        "MLB Leaders",
		Author:      "rs7q5",
		Summary:     "Get MLB league leaders",
		Desc:        "Get the top 2 (3 stats) or 3 (1 stat) league leaders in various MLB stats.",
		FileName:    "mlb_leaders.star",
		PackageName: "mlbleaders",
		Source:  source,
	}
}
