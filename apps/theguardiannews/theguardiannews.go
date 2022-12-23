// Package theguardiannews gets latest new articles from The Guardian public/open API and displays up to 3 articles for selected edition
package theguardiannews

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed theguardiannews.star
var source []byte

// New creates instance of applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "theguardiannews",
		Name:        "The Guardian News",
		Author:      "jvivona",
		Summary:     "Guardian News Headlines",
		Desc:        "Gets latest new articles from The Guardian and displays up to 3 articles for selected edition.",
		FileName:    "theguardiannews.star",
		PackageName: "theguardiannews",
		Source:      source,
	}
}
