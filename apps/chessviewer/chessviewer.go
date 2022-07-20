// Package chessviewer provides details for the Chess Viewer applet.
package chessviewer

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed chess_viewer.star
var source []byte

// New creates a new instance of the Chess Viewer applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "chess-viewer",
		Name:        "Chess Viewer",
		Author:      "Neal Wright",
		Summary:     "Shows Active Chess Games",
		Desc:        "This app shows a visual representation of currently active chess games for a given user on Chess.com.",
		FileName:    "chess_viewer.star",
		PackageName: "chessviewer",
		Source:  source,
	}
}
