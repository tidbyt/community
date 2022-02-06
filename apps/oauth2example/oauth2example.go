// Package oauth2example provides details for the OAuth2 Example applet.
package oauth2example

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed oauth2_example.star
var source []byte

// New creates a new instance of the OAuth2 Example applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "oauth2-example",
		Name:        "OAuth2 Example",
		Author:      "Mark",
		Summary:     "OAuth2 example app",
		Desc:        "An OAuth2 example app.",
		FileName:    "oauth2_example.star",
		PackageName: "oauth2example",
		Source:  source,
	}
}
