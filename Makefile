clean:
	rm -f community-tools

build: clean
	go build -v ./...
	go build -o community-tools tidbyt.dev/community/tools

lint:
	pixlet lint -r ./

format:
	pixlet format -r ./

test:
	pixlet check -r ./

app:
	@ pixlet create

migrate:
	go run tools/main.go migrate
