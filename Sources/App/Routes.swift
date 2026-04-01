// Copyright 2026 Wayne W Bishop. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Vapor
import Quiver

// This demo mimics the functionality of a vector database.
// In production, vectors would be stored in SQLite, Postgres, or any
// data source — Quiver handles all the pre and post data processing:
// similarity scoring, search ranking, classification, and feature scaling.
// The [Double] from Codable JSON IS the [Double] Quiver computes on.
// No Python bridge, no subprocess, no serialization boundary.

func routes(_ app: Application) throws {

    // Health check
    app.get("health") { _ in "Quiver Demo Server is running" }

    // Cosine similarity between two vectors — the operation that
    // powers recommendation engines, search ranking, and duplicate
    // detection. Runs in microseconds inside the request path.
    app.post("similarity") { request async throws -> SimilarityResponse in
        let input = try request.content.decode(SimilarityRequest.self)
        let score = input.vectorA.cosineOfAngle(with: input.vectorB)
        return SimilarityResponse(similarity: score)
    }

    // Batch cosine similarity across an entire collection in one call.
    // No database query, no vector index — Quiver computes directly
    // on the arrays.
    app.post("search") { request async throws -> [SearchResult] in
        let input = try request.content.decode(SearchRequest.self)
        let scores = input.catalog.cosineSimilarities(to: input.query)
        let topMatches = scores.topIndices(k: input.topK)
        return topMatches.map { SearchResult(index: $0.index, score: $0.score) }
    }

    // Classify a new data point using KNN trained on the provided data.
    // In production, the trained model would be loaded from Codable
    // persistence rather than retrained per request.
    app.post("classify") { request async throws -> ClassifyResponse in
        let input = try request.content.decode(ClassifyRequest.self)

        // FeatureScaler normalizes columns so no single feature dominates
        let scaler = FeatureScaler.fit(features: input.trainingFeatures)

        // KNN learns from the scaled training data
        let model = KNearestNeighbors.fit(
            features: scaler.transform(input.trainingFeatures),
            labels: input.trainingLabels, k: 3)

        let scaled = scaler.transform(input.newSamples)
        let predictions = model.predict(scaled)
        return ClassifyResponse(predictions: predictions)
    }
}
