package com.microservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

public class HelloController {

    @GetMapping("/api/hello")
    public ResponseEntity<HelloResponse> hello(
            @RequestParam(defaultValue = "World") String name) {
        HelloResponse response = new HelloResponse("Hello, " + name + "!");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/api/version")
    public ResponseEntity<VersionResponse> version() {
        VersionResponse response = new VersionResponse("1.1.0", "New /api/version endpoint added");
        return ResponseEntity.ok(response);
    }

    public static class HelloResponse {
        private String message;

        public HelloResponse(String message) {
            this.message = message;
        }

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }
    }

    public static class VersionResponse {
        private String version;
        private String description;

        public VersionResponse(String version, String description) {
            this.version = version;
            this.description = description;
        }

        public String getVersion() {
            return version;
        }

        public void setVersion(String version) {
            this.version = version;
        }

        public String getDescription() {
            return description;
        }

        public void setDescription(String description) {
            this.description = description;
        }
    }
}
