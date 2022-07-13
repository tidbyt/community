// Package displaymyip provides details for the Display My IP applet.
package displaymyip

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed display_my_ip.star
var source []byte

// New creates a new instance of the Display My IP applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "display-my-ip",
		Name:        "Display My IP",
		Author:      "Nick Kuzmik (github.com/kuzmik)",
		Summary:     "Displays your public IP",
		Desc:        "Displays the public IP of the network to which your Tidbyt is connected.",
		FileName:    "display_my_ip.star",
		PackageName: "displaymyip",
		Source:  source,
	}
}
