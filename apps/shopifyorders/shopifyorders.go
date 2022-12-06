// Package shopifyorders provides details for the Shopify Orders applet.
package shopifyorders

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shopify_orders.star
var source []byte

// New creates a new instance of the Shopify Orders applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shopify-orders",
		Name:        "Shopify Orders",
		Author:      "Shopify",
		Summary:     "Show Shopify orders count",
		Desc:        "Show your Shopify store orders count over a specific time period.",
		FileName:    "shopify_orders.star",
		PackageName: "shopifyorders",
		Source:  source,
	}
}
