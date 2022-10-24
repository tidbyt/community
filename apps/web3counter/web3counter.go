// Package web3counter provides details for the Web 3 Counter applet.
package web3counter

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed web_3_counter.star
var source []byte

// New creates a new instance of the Web 3 Counter applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "web-3-counter",
		Name:        "Web 3 Counter",
		Author:      "Nick Kuzmik (github.com/kuzmik)",
		Summary:     "Expose web3 as a scam",
		Desc:        "Displays the total dollar value of lost assets due to various crypto scams, rugpulls, and crashes. Data comes from web3isgoinggreat.com, which is very tongue-in-cheek.",
		FileName:    "web_3_counter.star",
		PackageName: "web3counter",
		Source:  source,
	}
}
