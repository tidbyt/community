// Package showthis provides details for the ShowThis applet.
package showthis

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed showthis.star
var source []byte

// New creates a new instance of the ShowThis applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "showthis",
		Name:        "ShowThis",
		Author:      "Jan Pichler",
		Summary:     "Shows info from a URL",
		Desc:        "This app displays information it retrieves from a custom URL that can be defined in the app settings. It can fetch and display data from your web services, low-code platforms etc., without having to implement a custom Tidbyt app. For information on how to use this app, visit https://github.com/janpi/tidbyt-showthis.",
		FileName:    "showthis.star",
		PackageName: "showthis",
		Source:      source,
	}
}
