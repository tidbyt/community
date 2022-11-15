// Package howoldami provides details for the How Old Am I applet.
package howoldami

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed howoldami.star
var source []byte

// New creates a new instance of the How Old Am I applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "how-old-am-i",
		Name:        "How Old Am I",
		Author:      "mabroadfo1027",
		Summary:     "Calculates age",
		Desc:        "Calculates age based on given date and time.",
		FileName:    "howoldami.star",
		PackageName: "howoldami",
		Source:  source,
	}
}
