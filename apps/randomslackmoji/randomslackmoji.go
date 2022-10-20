// Package randomslackmoji provides details for the Random Slackmoji applet.
package randomslackmoji

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed random_slackmoji.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the Random Slackmoji applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "random-slackmoji",
		Name:        "Random Slackmoji",
		Author:      "btjones",
		Summary:     "Displays a random Slackmoji",
		Desc:        "Displays a random image from slackmojis.com!",
		FileName:    "random_slackmoji.star",
		PackageName: "randomslackmoji",
		Source:      source,
	}
}
