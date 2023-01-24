// Package stripesales provides details for the Stripe Sales applet.
package stripesales

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed stripe_sales.star
var source []byte

// New creates a new instance of the Stripe Sales applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "stripe-sales",
		Name:        "Stripe Sales",
		Author:      "Jon Bilous",
		Summary:     "Shows your Stripe sales",
		Desc:        "Shows the order count and total sum of sales you've made today on Stripe.",
		FileName:    "stripe_sales.star",
		PackageName: "stripesales",
		Source:      source,
	}
}
