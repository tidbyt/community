// Package testpatterns provides details for the Test Patterns applet.
package testpatterns

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed test_patterns.star
var source []byte

// New creates a new instance of the Test Patterns applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "test-patterns",
		Name:        "Test Patterns",
		Author:      "harrisonpage",
		Summary:     "Pretty test patterns",
		Desc:        "Test patterns are as old as TV broadcasts.",
		FileName:    "test_patterns.star",
		PackageName: "testpatterns",
		Source:  source,
	}
}
