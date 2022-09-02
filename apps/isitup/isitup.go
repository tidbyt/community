// Package isitup checks to see if a web site is up or not
package isitup

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

var source []byte

func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "isitup",
		Name:        "Is It Up?",
		Author:      "Jonesie",
		Summary:     "Looks for a 200-299 response from a site and optionally the get version from the JSON response, e.g. { 'version' : '1.2.3.4' } ",
		Desc:        "Displays OK or Failed with response code if not.",
		FileName:    "isitup.star",
		PackageName: "isitup",
		Source:  	 source,
	}
}
