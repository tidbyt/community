// Package dailykanji provides details for the DailyKanji applet.
package dailykanji

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed dailykanji.star
var source []byte

// New creates a new instance of the DailyKanji applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "dailykanji",
		Name:        "DailyKanji",
		Author:      "Robert Ison",
		Summary:     "Displays a random Kanji",
		Desc:        "Displays a random Kanji character with translation.",
		FileName:    "dailykanji.star",
		PackageName: "dailykanji",
		Source:  source,
	}
}
