// Package shopifyneworder provides details for the Shopify New Order applet.
package shopifyneworder

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shopify_new_order.star
var source []byte

// New creates a new instance of the Shopify New Order applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shopify-new-order",
		Name:        "Shopify items",
		Author:      "Shopify",
		Summary:     "See what’s selling",
		Desc:        "Display the products being sold in every order so you can easily track your best sellers.",
		FileName:    "shopify_new_order.star",
		PackageName: "shopifyneworder",
		Source:  source,
	}
}
