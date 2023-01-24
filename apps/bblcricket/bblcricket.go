// Package bblcricket provides details for the BBL Cricket applet.
package bblcricket

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed bbl_cricket.star
var source []byte

// New creates a new instance of the BBL Cricket applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "bbl-cricket",
		Name:        "BBL Cricket",
		Author:      "M0ntyP",
		Summary:     "Shows BBL scores",
		Desc:        "This app takes the selected team and displays the current match situation - showing overall team score, batsmen scores, lead/deficit, overs bowled, run rate and required run rate for the team batting second. If a match for the selected team has just completed, it will show the match result or if there is an upcoming match it will show the teams win-loss record and the scheduled start time of the match, in the users timezone. If there is nothing coming up in the next day or so (as determined by the Cricinfo API), it will no show that there are no matches scheduled.",
		FileName:    "bbl_cricket.star",
		PackageName: "bblcricket",
		Source:  source,
	}
}
