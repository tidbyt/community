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
		Name:        "Shopify Stats",
		Author:      "Shopify",
		Summary:     "Time period sales tracker",
		Desc:        "Show your sales from a specific time period like Black Friday, peak selling seasons, and more.",
		FileName:    "shopify_sales.star",
		PackageName: "shopifysales",
		Source:  source,
	}
}
