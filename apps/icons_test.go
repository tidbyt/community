package apps_test

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"tidbyt.dev/community/apps"
	"tidbyt.dev/pixlet/runtime"
	"tidbyt.dev/pixlet/schema"
)

func TestAllIcons(t *testing.T) {
	for _, m := range apps.GetManifests() {
		applet := runtime.Applet{}

		runtime.InitCache(runtime.NewInMemoryCache())

		err := applet.Load(m.Name, m.Source, nil)
		assert.NoError(t, err)

		s := schema.Schema{}
		schemaStr := applet.GetSchema()
		if schemaStr == "" {
			continue
		}
		err = json.Unmarshal([]byte(schemaStr), &s)
		assert.NoError(t, err)

		for _, field := range s.Fields {
			if field.Icon == "" {
				continue
			}

			if _, ok := apps.IconsMap[field.Icon]; !ok {
				t.Errorf("app '%s' contains unknown icon: '%s'", applet.Filename, field.Icon)
			}
		}
	}
}
