clean:
	rm -f community-tools

build: clean
	go build -v ./...
	go build -o community-tools tidbyt.dev/community/tools

lint:
	golangci-lint run

test:
	go test -v -cover ./...

app:
	@ go run tools/main.go create
