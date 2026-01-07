package com.example.backend;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;

import java.io.*;
import java.net.InetSocketAddress;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Simple Backend Application for Infrastructure Demo
 *
 * This is a minimal Java HTTP server that:
 * - Serves a /health endpoint
 * - Serves a /api/items endpoint that queries PostgreSQL
 *
 * Designed to run on Java 8 for legacy environment simulation.
 */
public class BackendApp {

    private static final int PORT = 8080;
    private static String DB_HOST;
    private static String DB_PORT;
    private static String DB_NAME;
    private static String DB_USER;
    private static String DB_PASSWORD;

    public static void main(String[] args) throws Exception {
        // Read configuration from system properties or environment
        DB_HOST = getConfig("DB_HOST", "database");
        DB_PORT = getConfig("DB_PORT", "5432");
        DB_NAME = getConfig("DB_NAME", "appdb");
        DB_USER = getConfig("DB_USER", "appuser");
        DB_PASSWORD = getConfig("DB_PASSWORD", "apppassword");

        System.out.println("Starting Backend Application...");
        System.out.println("Database: " + DB_HOST + ":" + DB_PORT + "/" + DB_NAME);

        // Load PostgreSQL driver
        try {
            Class.forName("org.postgresql.Driver");
            System.out.println("PostgreSQL driver loaded");
        } catch (ClassNotFoundException e) {
            System.err.println("PostgreSQL driver not found!");
            throw e;
        }

        // Create HTTP server
        HttpServer server = HttpServer.create(new InetSocketAddress(PORT), 0);

        // Register handlers
        server.createContext("/health", new HealthHandler());
        server.createContext("/api/items", new ItemsHandler());
        server.createContext("/", new RootHandler());

        server.setExecutor(null);
        server.start();

        System.out.println("Backend server started on port " + PORT);
        System.out.println("Endpoints:");
        System.out.println("  GET /health    - Health check");
        System.out.println("  GET /api/items - List items from database");
    }

    private static String getConfig(String name, String defaultValue) {
        String value = System.getProperty(name);
        if (value == null || value.isEmpty()) {
            value = System.getenv(name);
        }
        return value != null && !value.isEmpty() ? value : defaultValue;
    }

    private static Connection getConnection() throws SQLException {
        String url = String.format("jdbc:postgresql://%s:%s/%s", DB_HOST, DB_PORT, DB_NAME);
        return DriverManager.getConnection(url, DB_USER, DB_PASSWORD);
    }

    // Root handler
    static class RootHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = "{\"message\": \"Backend API\", \"endpoints\": [\"/health\", \"/api/items\"]}";
            sendJsonResponse(exchange, 200, response);
        }
    }

    // Health check handler
    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            boolean dbHealthy = false;
            String dbMessage = "";

            try (Connection conn = getConnection()) {
                try (Statement stmt = conn.createStatement()) {
                    ResultSet rs = stmt.executeQuery("SELECT 1");
                    if (rs.next()) {
                        dbHealthy = true;
                        dbMessage = "connected";
                    }
                }
            } catch (SQLException e) {
                dbMessage = e.getMessage();
            }

            String status = dbHealthy ? "healthy" : "unhealthy";
            int statusCode = dbHealthy ? 200 : 503;

            String response = String.format(
                "{\"status\": \"%s\", \"database\": {\"status\": \"%s\", \"message\": \"%s\"}, \"java_version\": \"%s\"}",
                status,
                dbHealthy ? "up" : "down",
                escapeJson(dbMessage),
                System.getProperty("java.version")
            );

            sendJsonResponse(exchange, statusCode, response);
        }
    }

    // Items API handler
    static class ItemsHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if (!"GET".equals(exchange.getRequestMethod())) {
                String response = "{\"error\": \"Method not allowed\"}";
                sendJsonResponse(exchange, 405, response);
                return;
            }

            try (Connection conn = getConnection()) {
                List<String> items = new ArrayList<>();

                try (Statement stmt = conn.createStatement()) {
                    ResultSet rs = stmt.executeQuery(
                        "SELECT id, name, description, created_at FROM items ORDER BY id"
                    );

                    while (rs.next()) {
                        String item = String.format(
                            "{\"id\": %d, \"name\": \"%s\", \"description\": \"%s\", \"created_at\": \"%s\"}",
                            rs.getInt("id"),
                            escapeJson(rs.getString("name")),
                            escapeJson(rs.getString("description")),
                            rs.getTimestamp("created_at").toString()
                        );
                        items.add(item);
                    }
                }

                String response = "{\"items\": [" + String.join(", ", items) + "], \"count\": " + items.size() + "}";
                sendJsonResponse(exchange, 200, response);

            } catch (SQLException e) {
                String response = String.format(
                    "{\"error\": \"Database error\", \"message\": \"%s\"}",
                    escapeJson(e.getMessage())
                );
                sendJsonResponse(exchange, 500, response);
            }
        }
    }

    private static void sendJsonResponse(HttpExchange exchange, int statusCode, String response) throws IOException {
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        byte[] bytes = response.getBytes("UTF-8");
        exchange.sendResponseHeaders(statusCode, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
