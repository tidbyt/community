// Package nft provides details for the NFT applet.
package nft

import (
	_ "embed"

	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/manifest"
)

//go:embed nft.star
var source []byte

func init() {
	apps.Manifests = append(apps.Manifests, New())
}

// New creates a new instance of the NFT applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "nft",
		Name:        "NFT",
		Author:      "nipterink",
		Summary:     "Random Opensea NFT",
		Desc:        "Displays a random NFT associated with an Ethereum public address.",
		FileName:    "nft.star",
		PackageName: "nft",
		Source:      source,
	}
}
