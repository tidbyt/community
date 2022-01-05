package community_test

import (
	_ "embed"
	"io/ioutil"
	"testing"

	"github.com/stretchr/testify/assert"
	"tidbyt.dev/community-apps/apps/community"
)

//go:embed testdata/source.star
var source []byte

func TestApp(t *testing.T) {
	app := community.App{
		Name:    "Foo Tracker",
		Summary: "Track realtime foo",
		Desc:    "The foo tracker provides realtime feeds for foo.",
		Author:  "Tidbyt",
		Source:  source,
	}

	expected, err := ioutil.ReadFile("testdata/source.star")
	assert.NoError(t, err)
	assert.Equal(t, app.Source, expected)
}
