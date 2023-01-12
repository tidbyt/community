// Package shopifymemories provides details for the Shopify Memories applet.
package shopifymemories

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shopify_memories.star
var source []byte

// New creates a new instance of the Shopify Memories applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shopify-memories",
		Name:        "Shopify Memories",
		Author:      "Shopify",
		Summary:     "Remember your journey",
		Desc:        "Showcase some of your store’s most significant memories like your first sale, anniversaries, and more.",
		FileName:    "shopify_memories.star",
		PackageName: "shopifymemories",
		Source:  source,
	}
}
