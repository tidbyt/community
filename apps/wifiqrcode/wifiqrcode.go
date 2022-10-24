// Package wifiqrcode provides details for the WiFi QR Code applet.
package wifiqrcode

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed wifi_qr_code.star
var source []byte

// New creates a new instance of the WiFi QR Code applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "wifi-qr-code",
		Name:        "WiFi QR Code",
		Author:      "misusage",
		Summary:     "Creates a WiFi QR code",
		Desc:        "This app creates a scannable WiFi QR code. It is not compatible with Enterprise networks. Since there are display limitations with the Tidbyt, not all networks will be able to be encoded. Simply scan the QR code and your phone will join the WiFi network.",
		FileName:    "wifi_qr_code.star",
		PackageName: "wifiqrcode",
		Source:  source,
	}
}
