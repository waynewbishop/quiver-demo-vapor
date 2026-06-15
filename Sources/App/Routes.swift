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
    //
    // The response also returns Quiver's mean() and standardDeviation()
    // over the full catalog of similarity scores, plus a z-score on
    // every hit. Callers see not just "0.82" but "2.1 SD above catalog
    // mean" — a confident match versus a noisy one.
    app.get("search") { request throws -> SearchResponse in
        guard let query = request.query[String.self, at: "q"] else {
            throw Abort(.badRequest, reason: "Missing query parameter ?q=")
        }
        guard let outcome = store.searchWithStats(query: query) else {
            throw Abort(.badRequest, reason: "Query produced no embedding")
        }
        let mean = outcome.distribution.mean() ?? 0.0
        let std = outcome.distribution.standardDeviation() ?? 0.0
        let results = outcome.top.map { hit -> SearchResult in
            let z = std > 0 ? (hit.score - mean) / std : 0.0
            return SearchResult(rank: hit.rank,
                                description: hit.text,
                                similarity: hit.score,
                                zScore: z)
        }
        let stats = SearchStats(catalogSize: outcome.distribution.count,
                                mean: mean,
                                standardDeviation: std)
        return SearchResponse(results: results, stats: stats)
    }
}
