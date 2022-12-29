// Package movienight provides details for the Movie Night applet.
package movienight

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed movie_night.star
var source []byte

// New creates a new instance of the Movie Night applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "movie-night",
		Name:        "Movie Night",
		Author:      "Piper Gillman",
		Summary:     "Marquee for a Movie Night",
		Desc:        "Displays a marquee for a movie title along with a countdown to the movie night.",
		FileName:    "movie_night.star",
		PackageName: "movienight",
		Source:  source,
	}
}
