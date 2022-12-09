// Package ordertrends provides details for the Order Trends applet.
package ordertrends

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed order_trends.star
var source []byte

// New creates a new instance of the Order Trends applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shopify-order-trends",
		Name:        "Shopify Orders",
		Author:      "Shopify",
		Summary:     "Display order totals",
		Desc:        "Showcase your daily, weekly, monthly, or annual order totals.",
		FileName:    "order_trends.star",
		PackageName: "ordertrends",
		Source:  source,
	}
}
