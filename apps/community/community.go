// Package community provides structures and primitives to define apps.
package community

// App is a structure to define a starlark applet for Tidbyt in Go.
type App struct {
	// Name is the name of the applet. Ex. "Fuzzy Clock"
	Name string `json:"name"`
	// Summary is the short form of what this applet does. Ex. "Human readable
	// time".
	Summary string `json:"summary"`
	// Desc is the long form of what this applet does. Ex. "Display the time in
	// a groovy, human-readable way."
	Desc string `json:"desc"`
	// Author is the person or organization who contributed this applet. Ex,
	// "Max Timkovich"
	Author string `json:"author"`
	// Source is the starlark source code for this applet using the go `embed`
	// module.
	Source []byte `json:"-"`
}
