// Package moviequotes provides details for the Movie Quotes applet.
package moviequotes

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed movie_quotes.star
var source []byte

// New creates a new instance of the Movie Quotes applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "movie-quotes",
		Name:        "Movie Quotes",
		Author:      "Austin Fonacier",
		Summary:     "Random Movie Quotes",
		Desc:        "Random movie quote from AFI top 100 movie quotes.",
		FileName:    "movie_quotes.star",
		PackageName: "moviequotes",
		Source:  source,
	}
}
