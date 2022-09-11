// Package pulsechain provides details for the PulseChain applet.
package pulsechain

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed pulsechain.star
var source []byte

// New creates a new instance of the PulseChain applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "pulsechain",
		Name:        "PulseChain",
		Author:      "bretep",
		Summary:     "Price of PLS and PLSX",
		Desc:        "Display the price of PLS and PLSX. Choose between testnet and mainnet prices. After PulseChain mainnet launch, an update will be pushed to this app to display the correct mainnet price.",
		FileName:    "pulsechain.star",
		PackageName: "pulsechain",
		Source:  source,
	}
}
