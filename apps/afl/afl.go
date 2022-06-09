// Package afl provides details for the AFL applet.
package afl

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed afl.star
var source []byte

// New creates a new instance of the AFL applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "afl",
		Name:        "AFL",
		Author:      "andymcrae",
		Summary:     "AFL standings",
		Desc:        "Display the current Australian Football League standings and the next game time/date for a selected team.",
		FileName:    "afl.star",
		PackageName: "afl",
		Source:  source,
	}
}
