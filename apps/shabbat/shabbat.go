// Package shabbat provides details for the Shabbat applet.
package shabbat

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shabbat.star
var source []byte

// New creates a new instance of the Shabbat applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shabbat",
		Name:        "Shabbat",
		Author:      "dinosaursrarr",
		Summary:     "Weekly shabbat times",
		Desc:        "Displays weekly shabbat times.",
		FileName:    "shabbat.star",
		PackageName: "shabbat",
		Source:      source,
	}
}
