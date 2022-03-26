// Package finevent provides details for the Finevent applet.
package finevent

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed finevent.star
var source []byte

// New creates a new instance of the Finevent applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "finevent",
		Name:        "Finevent",
		Author:      "Rob Kimball",
		Summary:     "Economic Releases",
		Desc:        "Displays recent and upcoming economic releases.",
		FileName:    "finevent.star",
		PackageName: "finevent",
		Source:  source,
	}
}
