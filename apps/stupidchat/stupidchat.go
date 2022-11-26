// Package stupidchat provides details for the Stupid Chat applet.
package stupidchat

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed stupid_chat.star
var source []byte

// New creates a new instance of the Stupid Chat applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "stupid-chat",
		Name:        "Stupid Chat",
		Author:      "harrisonpage",
		Summary:     "Tidbyt Messaging",
		Desc:        "Send messages to your Tidbyt via https://stupid.chat or an API.",
		FileName:    "stupid_chat.star",
		PackageName: "stupidchat",
		Source:  source,
	}
}
