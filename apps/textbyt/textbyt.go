// Package textbyt provides details for the Textbyt applet.
package textbyt

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed textbyt.star
var source []byte

// New creates a new instance of the Textbyt applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "textbyt",
		Name:        "Textbyt",
		Author:      "Josh Reed",
		Summary:     "Display text messages",
		Desc:        "Display text messages on your Tidbyt. To get started, text 'new' to 610-TEXTBYT (610-839-8298). The service will reply with a unique feed id. Enter this feed id into the Textbyt app. To send your first message, start your text with `<name>@<feed id>`. The service will associate the name and feed id with your number so future texts will go to the same Tidbyt. NOTE: The API and SMS service that powers Textbyt is not affiliated with Tidbyt, Inc. Use at your own risk.",
		FileName:    "textbyt.star",
		PackageName: "textbyt",
		Source:  source,
	}
}
