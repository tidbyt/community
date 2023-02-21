// Package yulelog provides details for the Yule Log applet.
package yulelog

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed yule_log.star
var source []byte

// New creates a new instance of the Yule Log applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "yule-log",
		Name:        "Yule Log",
		Author:      "Tidbyt",
		Summary:     "A pixel fireplace",
		Desc:        "A pixel fireplace to add some warmth to your Tidbyt.",
		FileName:    "yule_log.star",
		PackageName: "yulelog",
		Source:  source,
	}
}
