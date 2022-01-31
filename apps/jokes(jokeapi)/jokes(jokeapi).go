// Package jokes(jokeapi) provides details for the Jokes (JokeAPI) applet.
package jokes(jokeapi)

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed jokes_(jokeapi).star
var source []byte

// New creates a new instance of the Jokes (JokeAPI) applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "jokes-(jokeapi)",
		Name:        "Jokes (JokeAPI)",
		Author:      "rs7q5 (RIS)",
		Summary:     "Displays jokes from JokeAPI",
		Desc:        "Displays different jokes from JokeAPI.",
		FileName:    "jokes_(jokeapi).star",
		PackageName: "jokes(jokeapi)",
		Source:  source,
	}
}
