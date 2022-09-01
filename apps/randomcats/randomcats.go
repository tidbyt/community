// Package randomcats provides details for the Random Cats applet.
package randomcats

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed random_cats.star
var source []byte

// New creates a new instance of the Random Cats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "random-cats",
		Name:        "Random Cats",
		Author:      "mrrobot245",
		Summary:     "Shows pictures of cats",
		Desc:        "Shows random pictures/gifs of cats. Powered by Cat as a Service (cataas.com).",
		FileName:    "random_cats.star",
		PackageName: "randomcats",
		Source:      source,
	}
}
