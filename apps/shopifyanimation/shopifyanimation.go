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
		Name:        "Shopify Animation",
		Author:      "Shopify",
		Summary:     "Displays fun animations",
		Desc:        "Shoppy, the Shopify shopping bag would like to visit your TidByt.",
		FileName:    "shopify_animation.star",
		PackageName: "shopifyanimation",
		Source:  source,
	}
}
