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
		Name:        "Order Trends",
		Author:      "Shopify",
		Summary:     "Show trending order counts",
		Desc:        "Show daily, weekly, monthly and/or yearly order counts for your Shopify store.",
		FileName:    "order_trends.star",
		PackageName: "ordertrends",
		Source:  source,
	}
}
