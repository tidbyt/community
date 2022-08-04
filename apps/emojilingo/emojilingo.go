// Package emojilingo provides details for the Emoji Lingo applet.
package emojilingo

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed emoji_lingo.star
var source []byte

// New creates a new instance of the Emoji Lingo applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "emoji-lingo",
		Name:        "Emoji Lingo",
		Author:      "Cedric Sam",
		Summary:     "Random multilingual emojis",
		Desc:        "Displays a random emoji and its unique short text annotation from the Unicode Consortium in a given language.",
		FileName:    "emoji_lingo.star",
		PackageName: "emojilingo",
		Source:  source,
	}
}
