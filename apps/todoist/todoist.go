// Package todoist provides details for the Todoist applet.
package todoist

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed todoist.star
var source []byte

// New creates a new instance of the Todoist applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "todoist",
		Name:        "Todoist",
		Author:      "zephyern",
		Summary:     "Integration with Todoist",
		Desc:        "Shows the number of tasks you have due today.",
		FileName:    "todoist.star",
		PackageName: "todoist",
		Source:  source,
	}
}
