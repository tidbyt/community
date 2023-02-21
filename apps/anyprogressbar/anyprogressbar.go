// Package anyprogressbar provides details for the Any Progressbar applet.
package anyprogressbar

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed any_progressbar.star
var source []byte

// New creates a new instance of the Any Progressbar applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "any-progressbar",
		Name:        "Any Progressbar",
		Author:      "wojciechka",
		Summary:     "AnyProgressbar",
		Desc:        "Show any progress bar using properties.",
		FileName:    "any_progressbar.star",
		PackageName: "anyprogressbar",
		Source:  source,
	}
}
