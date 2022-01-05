package manifest

import (
	"fmt"
	"strings"
)

const (
	// Our longest app name to date. This can be updated, but it will need to
	// be tested in the mobile app.
	MaxNameLength = 16

	// Our longest app summary to date. This can be updated, but it will need to
	// be tested in the mobile app.
	MaxSummaryLength = 27
)

var punctuation []string = []string{
	".",
	"!",
	"?",
}

// ValidateName ensures the app name provided adheres to the standards for app
// names. We're picky here because these will display in the Tidbyt mobile app
// and need to display properly.
func ValidateName(name string) error {
	if name != strings.Title(name) {
		return fmt.Errorf("'%s' should be title case, 'Fuzzy Clock' for example", name)
	}

	if len(name) > MaxNameLength {
		return fmt.Errorf("app names need to be less then %d characters", MaxNameLength)
	}

	return nil
}

// ValidateSummary ensures the app summary provided adheres to the standards
// for app summaries. We're picky here because these will display in the Tidbyt
// mobile app and need to display properly.
func ValidateSummary(summary string) error {
	if len(summary) > MaxSummaryLength {
		return fmt.Errorf("app summaries need to be less then %d characters", MaxSummaryLength)
	}

	for _, punct := range punctuation {
		if strings.HasSuffix(summary, punct) {
			return fmt.Errorf("app summaries should not end in punctuation")
		}
	}

	words := strings.Split(summary, " ")
	if len(words) > 0 && words[0] != strings.Title(words[0]) {
		return fmt.Errorf("app summaries should start with an uppercased character")
	}

	return nil
}

// ValidateDesc ensures the app description provided adheres to the standards
// for app descriptions. We're picky here because these will display in the
// Tidbyt mobile app and need to display properly.
func ValidateDesc(desc string) error {
	found := false
	for _, punct := range punctuation {
		if strings.HasSuffix(desc, punct) {
			found = true
		}
	}
	if !found {
		return fmt.Errorf("app descriptions should end in punctuation")
	}

	words := strings.Split(desc, " ")
	if len(words) > 0 && words[0] != strings.Title(words[0]) {
		return fmt.Errorf("app descriptions should start with an uppercased character")
	}

	return nil
}

// ValidateAuthor ensures the app author provided adheres to the standards
// for app author. We're picky here because these will display in the
// Tidbyt mobile app and need to display properly.
func ValidateAuthor(author string) error {
	// I don't know what validation where need here just yet. We're going to
	// have to eyeball it in pull requests until we get a sense of what doesn't
	// work.
	return nil
}
