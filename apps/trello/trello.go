// Package trello provides details for the Trello applet.
package trello

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed trello.star
var source []byte

// New creates a new instance of the Trello applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "trello",
		Name:        "Trello",
		Author:      "remh",
		Summary:     "List cards from Trello",
		Desc:        "A simple app to list first 3 cards from the column of a Trello board.",
		FileName:    "trello.star",
		PackageName: "trello",
		Source:  source,
	}
}
