package com.vicgroup.keycloak.facial;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;

public class DeepFaceService {

    private final String baseUrl;
    private final ObjectMapper om = new ObjectMapper();
    private final HttpClient client = HttpClient.newHttpClient();

    public DeepFaceService(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    /** Devuelve true si la cara coincide con la referencia guardada */
    public boolean verify(String vetId, String probeBase64) {
        try {
            String json = om.writeValueAsString(Map.of(
                    "vetId", vetId,
                    "imageBase64", probeBase64
            ));

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/verify-facial"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                throw new RuntimeException("DeepFace server returned " + response.statusCode());
            }

            Map<?, ?> map = om.readValue(response.body(), Map.class);
            return Boolean.TRUE.equals(map.get("match"));

        } catch (IOException | InterruptedException e) {
            throw new RuntimeException("DeepFace call failed", e);
        }
    }
}
