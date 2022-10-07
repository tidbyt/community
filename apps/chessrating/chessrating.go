// Package chessrating provides details for the Chess Rating applet.
package chessrating

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed chess_rating.star
var source []byte

// New creates a new instance of the Chess Rating applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "chess-rating",
		Name:        "Chess Rating",
		Author:      "NickAlvesX",
		Summary:     "Ratings from Chess.com",
		Desc:        "Show your Rapid, Blitz and Bullet Ratings from Chess.com.",
		FileName:    "chess_rating.star",
		PackageName: "chessrating",
		Source:  source,
	}
}
