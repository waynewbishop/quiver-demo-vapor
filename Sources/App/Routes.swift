// Copyright 2026 Wayne W Bishop. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Vapor
import Quiver

// Four CRUD endpoints for a semantic running shoe catalog. Vapor
// handles HTTP routing and JSON serialization. Quiver handles the
// intelligence — every shoe added is automatically tokenized and
// embedded, and every search query is matched by meaning rather
// than keywords.

func routes(_ app: Application) throws {

    // The store is seeded with 15 real running shoes at startup.
    // Each shoe's description has already been converted to a
    // semantic vector by Quiver's tokenize → embed → meanVector
    // pipeline. Runners will recognize every shoe in the catalog.
    let store = seededStore()

    // List all shoes in the catalog
    app.get("products") { _ in
        store.descriptions
    }

    // Add a shoe. Quiver's text pipeline runs automatically inside
    // ProductStore.add() — the caller sends a plain text description,
    // and Quiver converts it into a searchable vector behind the scenes.
    app.post("products") { request throws -> HTTPStatus in
        let input = try request.content.decode(AddRequest.self)
        store.add(input.description)
        return .created
    }

    // Remove a shoe and its vector from the catalog
    app.delete("products", ":description") { request -> HTTPStatus in
        guard let description = request.parameters.get("description") else {
            throw Abort(.badRequest)
        }
        return store.remove(description) ? .ok : .notFound
    }

    // Semantic search — the hero endpoint. A plain text query like
    // "cushioned long run shoe" is converted to a vector, then
    // Quiver's cosineSimilarities ranks every shoe by directional
    // similarity. The NB 1080 and Nike Invincible float to the top
    // because their vectors point in the same direction as the query —
    // even though the exact words don't match.
    app.get("search") { request -> [SearchResult] in
        guard let query = request.query[String.self, at: "q"] else {
            throw Abort(.badRequest, reason: "Missing query parameter ?q=")
        }
        return store.search(query: query).map {
            SearchResult(rank: $0.rank, description: $0.label, similarity: $0.score)
        }
    }
}
