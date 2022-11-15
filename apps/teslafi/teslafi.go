// Package teslafi provides details for the TeslaFi applet.
package teslafi

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed teslafi.star
var source []byte

// New creates a new instance of the TeslaFi applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "teslafi",
		Name:        "TeslaFi",
		Author:      "mrrobot245",
		Summary:     "Shows charge/name/range",
		Desc:        "Shows your Teslas current Name, Charge in Mi/KM and battery %. Also shows if its charging or not.",
		FileName:    "teslafi.star",
		PackageName: "teslafi",
		Source:  source,
	}
}
