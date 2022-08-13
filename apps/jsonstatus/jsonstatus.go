// Package jsonstatus provides details for the JSON Status applet.
package jsonstatus

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed json_status.star
var source []byte

// New creates a new instance of the JSON Status applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "json-status",
		Name:        "JSON Status",
		Author:      "wojciechka",
		Summary:     "Items from JSON status",
		Desc:        "Retrieve one or more items from a JSON file available via a public URL and show it on your Tidbyt.",
		FileName:    "json_status.star",
		PackageName: "jsonstatus",
		Source:  source,
	}
}
