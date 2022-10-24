// Package shouldideploy provides details for the Should I Deploy applet.
package shouldideploy

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed should_i_deploy.star
var source []byte

// New creates a new instance of the Should I Deploy applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "should-i-deploy",
		Name:        "Should I Deploy",
		Author:      "humbertogontijo",
		Summary:     "Display shouldideploy.today",
		Desc:        "Display shouldideploy.today answer.",
		FileName:    "should_i_deploy.star",
		PackageName: "shouldideploy",
		Source:  source,
	}
}
