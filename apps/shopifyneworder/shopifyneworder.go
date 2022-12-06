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
		Name:        "Shopify New Order",
		Author:      "Shopify",
		Summary:     "Display recent orders",
		Desc:        "Display recent orders for your Shopify store.",
		FileName:    "shopify_new_order.star",
		PackageName: "shopifyneworder",
		Source:  source,
	}
}
