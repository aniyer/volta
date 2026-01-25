.PHONY: build up down logs restart

# Build the Flutter web app using the Docker container
build:
	docker compose --profile build run --rm flutter-build

# Start the services (backend + frontend)
up:
	docker compose up -d

# Stop all services
down:
	docker compose down

# View logs
logs:
	docker compose logs -f

# Rebuild and restart frontend
deploy: build
	docker compose restart volta-frontend
