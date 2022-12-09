// Package ordermoments provides details for the Order Moments applet.
package ordermoments

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed order_moments.star
var source []byte

// New creates a new instance of the Order Moments applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "order-moments",
		Name:        "Shopify Celebrate",
		Author:      "Shopify",
		Summary:     "Celebrate major moments",
		Desc:        "Get celebratory notifications when you hit specific order milestones.",
		FileName:    "order_moments.star",
		PackageName: "ordermoments",
		Source:  source,
	}
}
