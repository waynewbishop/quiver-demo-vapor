// Copyright 2026 Wayne W Bishop. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Vapor
import Quiver

// Four CRUD endpoints for a semantic product catalog. Vapor handles
// HTTP routing and JSON serialization. Quiver handles the intelligence —
// every product added is automatically tokenized and embedded, and
// every search query is matched by meaning rather than keywords.

func routes(_ app: Application) throws {

    // The store is seeded with 8 athletic products at startup.
    // Each product's description has already been converted to a
    // semantic vector by Quiver's tokenize → embed → meanVector pipeline.
    let store = seededStore()

    // List all products in the catalog
    app.get("products") { _ in
        store.descriptions
    }

    // Add a product. Quiver's text pipeline runs automatically inside
    // ProductStore.add() — the caller sends a plain text description,
    // and Quiver converts it into a searchable vector behind the scenes.
    app.post("products") { request throws -> HTTPStatus in
        let input = try request.content.decode(AddRequest.self)
        store.add(input.description)
        return .created
    }

    // Remove a product and its vector from the catalog
    app.delete("products", ":description") { request -> HTTPStatus in
        guard let description = request.parameters.get("description") else {
            throw Abort(.badRequest)
        }
        return store.remove(description) ? .ok : .notFound
    }

    // Semantic search — the hero endpoint. A plain text query is
    // converted to a vector, then Quiver's cosineSimilarities ranks
    // every product by directional similarity. "comfortable running
    // shoes" finds "cushioned shoes for easy running" because the
    // vectors point in the same direction — even though the words
    // don't match. Five Quiver calls, zero external services.
    app.get("search") { request -> [SearchResult] in
        guard let query = request.query[String.self, at: "q"] else {
            throw Abort(.badRequest, reason: "Missing query parameter ?q=")
        }
        return store.search(query: query).map {
            SearchResult(rank: $0.rank, description: $0.label, similarity: $0.score)
        }
    }
}
