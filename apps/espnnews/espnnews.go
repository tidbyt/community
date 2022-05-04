// Package espnnews provides details for the ESPN News applet.
package espnnews

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed espn_news.star
var source []byte

// New creates a new instance of the ESPN News applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "espn-news",
		Name:        "ESPN News",
		Author:      "rs7q5",
		Summary:     "Get top headlines from ESPN",
		Desc:        "Displays the top three headlines from the Top Headlines section on ESPN or a specific user-selected sport.",
		FileName:    "espn_news.star",
		PackageName: "espnnews",
		Source:  source,
	}
}
