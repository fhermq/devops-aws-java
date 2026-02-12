# Java Microservice Application

Spring Boot 3.x microservice with health checks, metrics, and sample API endpoints.

## Building

```bash
mvn clean package
```

## Running Locally

```bash
mvn spring-boot:run
```

## Docker

```bash
# Build image
docker build -t devops-aws-java:latest .

# Run container
docker run -p 8080:8080 devops-aws-java:latest
```

## Endpoints

- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /api/hello` - Sample API endpoint
- `GET /api/hello?name=World` - API with parameter
- `GET /actuator/prometheus` - Prometheus metrics

## Testing

```bash
mvn clean test
```
