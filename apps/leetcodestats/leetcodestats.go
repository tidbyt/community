// Package leetcodestats provides details for the LeetCodeStats applet.
package leetcodestats

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed leetcodestats.star
var source []byte

// New creates a new instance of the LeetCodeStats applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "leetcodestats",
		Name:        "LeetCodeStats",
		Author:      "Jake Manske",
		Summary:     "Gets LeetCode stats",
		Desc:        "Displays your LeetCode stats in a nice way.",
		FileName:    "leetcodestats.star",
		PackageName: "leetcodestats",
		Source:  source,
	}
}
