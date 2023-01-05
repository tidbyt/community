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
		Name:        "Shopify Select",
		Author:      "Shopify",
		Summary:     "Time period order tracker",
		Desc:        "View orders you've received during a specific time period like Black Friday, seasonal sales, holiday season, and more.",
		FileName:    "shopify_orders.star",
		PackageName: "shopifyorders",
		Source:  source,
	}
}
