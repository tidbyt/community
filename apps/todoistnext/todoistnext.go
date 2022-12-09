// Package todoistnext provides details for the Todoist Next applet.
package todoistnext

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed todoist_next.star
var source []byte

// New creates a new instance of the Todoist Next applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "todoist-next",
		Name:        "Todoist Next",
		Author:      "Alisdair/Akeslo",
		Summary:     "Todoist next due/overdue",
		Desc:        "Displays the next due or overdue task from todoist.",
		FileName:    "todoist_next.star",
		PackageName: "todoistnext",
		Source:  source,
	}
}
