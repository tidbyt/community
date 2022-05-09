// Package fullybinarytime provides details for the FullyBinaryTime applet.
package fullybinarytime

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed fullybinarytime.star
var source []byte

// New creates a new instance of the FullyBinaryTime applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "fullybinarytime",
		Name:        "FullyBinaryTime",
		Author:      "dinosaursrarr",
		Summary:     "A clock for nerds",
		Desc:        "Displays the current time using fully binary time. First divide the day into two 12 hour parts, then each of those into two 6 hour parts, then two 3 hour parts, and so on up to 16 bits of precision.",
		FileName:    "fullybinarytime.star",
		PackageName: "fullybinarytime",
		Source:  source,
	}
}
