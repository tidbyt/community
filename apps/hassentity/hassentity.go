// Package hassentity provides details for the Hass Entity applet.
package hassentity

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed hass_entity.star
var source []byte

// New creates a new instance of the Hass Entity applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "hass-entity",
		Name:        "Hass Entity",
		Author:      "InTheDaylight14",
		Summary:     "Display Hass entity state",
		Desc:        "Display an externally accessible Home Assistant entity state or attribute.",
		FileName:    "hass_entity.star",
		PackageName: "hassentity",
		Source:  source,
	}
}
