// Package jokesjokeapi provides details for the Jokes JokeAPI applet.
package jokesjokeapi

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed jokes_jokeapi.star
var source []byte

// New creates a new instance of the Jokes JokeAPI applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "jokes-jokeapi",
		Name:        "Jokes JokeAPI",
		Author:      "rs7q5",
		Summary:     "Displays jokes from JokeAPI",
		Desc:        "Displays different jokes from JokeAPI.",
		FileName:    "jokes_jokeapi.star",
		PackageName: "jokesjokeapi",
		Source:  source,
	}
}
