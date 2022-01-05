package manifest_test

import (
	_ "embed"
	"io/ioutil"
	"testing"

	"github.com/stretchr/testify/assert"
	"tidbyt.dev/community-apps/apps/manifest"
)

//go:embed testdata/source.star
var source []byte

func TestManifest(t *testing.T) {
	m := manifest.Manifest{
		Name:    "Foo Tracker",
		Summary: "Track realtime foo",
		Desc:    "The foo tracker provides realtime feeds for foo.",
		Author:  "Tidbyt",
		Source:  source,
	}

	expected, err := ioutil.ReadFile("testdata/source.star")
	assert.NoError(t, err)
	assert.Equal(t, m.Source, expected)
}
