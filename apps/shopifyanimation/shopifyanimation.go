// Package shopifyanimation provides details for the Shopify Animation applet.
package shopifyanimation

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shopify_animation.star
var source []byte

// New creates a new instance of the Shopify Animation applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shopify-animation",
		Name:        "Shoppy Pixels",
		Author:      "Shopify",
		Summary:     "Animated Shoppy app",
		Desc:        "Enjoy a retro animated experience with Shoppy, the entrepreneurs mascot.",
		FileName:    "shopify_animation.star",
		PackageName: "shopifyanimation",
		Source:  source,
	}
}
