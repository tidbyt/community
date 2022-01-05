package generator_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"tidbyt.dev/community/tools/generator"
)

func TestGeneratePackageName(t *testing.T) {
	type test struct {
		input string
		want  string
	}

	tests := []test{
		{input: "Cool App", want: "coolapp"},
		{input: "CoolApp", want: "coolapp"},
		{input: "cool-app", want: "coolapp"},
		{input: "cool_app", want: "coolapp"},
	}

	for _, tc := range tests {
		got := generator.GeneratePackageName(tc.input)
		assert.Equal(t, tc.want, got)
	}
}
