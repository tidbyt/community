clean:
	rm -f community-tools

build: clean
	go build -v ./...
	go build -o community-tools tidbyt.dev/community/tools

install-buildifier:
	go install github.com/bazelbuild/buildtools/buildifier@latest

lint:
	golangci-lint run
	buildifier -r ./

test:
	go test -v -cover ./...

app:
	@ go run tools/main.go create
