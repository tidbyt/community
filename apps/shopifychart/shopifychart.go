// Package shopifychart provides details for the Shopify Chart applet.
package shopifychart

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shopify_chart.star
var source []byte

// New creates a new instance of the Shopify Chart applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shopify-chart",
		Name:        "Shopify Chart",
		Author:      "kcharwood",
		Summary:     "Display daily ecomm metrics",
		Desc:        "Display daily Shopify metrics and charts for revenue, orders, or units.",
		FileName:    "shopify_chart.star",
		PackageName: "shopifychart",
		Source:  source,
	}
}
