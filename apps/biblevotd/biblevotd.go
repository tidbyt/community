// Package biblevotd provides details for the Bible VOTD applet.
package biblevotd

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed bible_votd.star
var source []byte

// New creates a new instance of the Bible VOTD applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "bible-votd",
		Name:        "Bible VOTD",
		Author:      "danrods",
		Summary:     "Shows a daily bible verse",
		Desc:        "Shows a bible verse on a daily cadence.",
		FileName:    "bible_votd.star",
		PackageName: "biblevotd",
		Source:  source,
	}
}
