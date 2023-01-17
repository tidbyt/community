// Package poktstats provides details for the POKT Stats applet.
package poktstats

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pokt_stats.star
var source []byte

// New creates a new instance of the POKT Stats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "pokt-stats",
		Name:        "POKT Stats",
		Author:      "al-bargsys",
		Summary:     "POKT Price and Height",
		Desc:        " Displays up-to-date statistics (currently POKT/USD price and latest block height) about the Pocket Networks blockchain for monitoring.",
		FileName:    "pokt_stats.star",
		PackageName: "poktstats",
		Source:  source,
	}
}
