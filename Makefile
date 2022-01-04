build:
	go build -o ca-tools tools/main.go

test:
	go test -v -cover ./...
