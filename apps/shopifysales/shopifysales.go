// Package shopifysales provides details for the Shopify Sales applet.
package shopifysales

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed shopify_sales.star
var source []byte

// New creates a new instance of the Shopify Sales applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shopify-sales",
		Name:        "Shopify Sales",
		Author:      "Shopify",
		Summary:     "Show Shopify sales data",
		Desc:        "Show your Shopify store sales generated over a specific time period.",
		FileName:    "shopify_sales.star",
		PackageName: "shopifysales",
		Source:  source,
	}
}
