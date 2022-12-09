// Package salestrends provides details for the Sales Trends applet.
package salestrends

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed sales_trends.star
var source []byte

// New creates a new instance of the Sales Trends applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "shopify-sales-trends",
		Name:        "Shopify Sales",
		Author:      "Shopify",
		Summary:     "Display sales totals",
		Desc:        "Showcase your daily, weekly, monthly, or annual sales totals.",
		FileName:    "sales_trends.star",
		PackageName: "salestrends",
		Source:  source,
	}
}
