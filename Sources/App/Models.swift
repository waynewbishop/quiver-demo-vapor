// Copyright 2026 Wayne W Bishop. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Vapor
import Quiver

// Quiver Demo — Semantic Product Search
//
// This file contains the entire Quiver integration. The ProductStore
// holds product descriptions alongside their semantic vectors. When
// a product is added, Quiver's text pipeline converts the description
// into a numeric vector. When a user searches, Quiver compares the
// query vector against every stored product and ranks them by meaning —
// not keywords. The same [Double] arrays that Vapor serializes as JSON
// are the same arrays Quiver computes on. No conversion step, no
// separate runtime, no vector database.

// MARK: - Word embeddings

// Hypothetical word vectors (4 dimensions for illustration). Words
// with similar meanings point in similar directions — "running" and
// "training" are close, while "trail" and "comfortable" are far apart.
// In production, these would come from a trained language model. These
// match the examples in Quiver's semantic search documentation.
let embeddings: [String: [Double]] = [
    "comfortable": [0.7, 0.8, 0.3, 0.1], "running":    [0.8, 0.7, 0.9, 0.2],
    "shoes":       [0.6, 0.9, 0.4, 0.1], "lightweight": [0.5, 0.6, 0.3, 0.2],
    "trail":       [0.4, 0.3, 0.8, 0.7], "sneakers":   [0.6, 0.8, 0.5, 0.2],
    "outdoor":     [0.3, 0.2, 0.7, 0.8], "training":   [0.7, 0.6, 0.8, 0.3],
    "rugged":      [0.3, 0.2, 0.9, 0.6], "fast":       [0.9, 0.5, 0.7, 0.1],
    "cushioned":   [0.6, 0.9, 0.2, 0.1], "easy":       [0.5, 0.7, 0.2, 0.1],
    "speed":       [0.9, 0.4, 0.8, 0.1], "grip":       [0.3, 0.3, 0.8, 0.7],
    "road":        [0.7, 0.6, 0.3, 0.2]
]

// MARK: - Product store

// Each product is a description string paired with its semantic vector.
// In a real app, products would live in a database — the vectors would
// be computed once at ingestion time and stored alongside the text.
// The final class with @unchecked Sendable allows shared mutable state
// across Vapor's concurrent route handlers. A production app would use
// a database or actor instead.
final class ProductStore: @unchecked Sendable {
    var descriptions: [String] = []
    var vectors: [[Double]] = []

    // Three Quiver calls turn a text description into a searchable vector:
    // tokenize() splits text into clean lowercase tokens,
    // embed(using:) looks up each token's vector from the dictionary,
    // meanVector() averages them into a single vector per product.
    func add(_ description: String) {
        let tokens = description.tokenize()
        guard let vector = tokens.embed(using: embeddings).meanVector() else { return }
        descriptions.append(description)
        vectors.append(vector)
    }

    func remove(_ description: String) -> Bool {
        guard let index = descriptions.firstIndex(of: description) else { return false }
        descriptions.remove(at: index)
        vectors.remove(at: index)
        return true
    }

    // Two Quiver calls rank the entire catalog by meaning:
    // cosineSimilarities(to:) scores every product against the query,
    // topIndices(k:labels:) returns the best matches with rank and score.
    // A search for "comfortable running shoes" finds "cushioned shoes
    // for easy running" even though the words don't match — because the
    // vectors point in the same direction.
    func search(query: String, topK: Int = 3) -> [(rank: Int, label: String, score: Double)] {
        let tokens = query.tokenize()
        guard let queryVector = tokens.embed(using: embeddings).meanVector() else { return [] }
        return vectors.cosineSimilarities(to: queryVector)
            .topIndices(k: topK, labels: descriptions)
    }
}

// MARK: - Seed data

// Simulated athletic product catalog. In a real app, these descriptions
// would come from a product database or content management system.
func seededStore() -> ProductStore {
    let store = ProductStore()
    store.add("rugged trail running shoes for outdoor terrain")
    store.add("lightweight running shoes for fast road training")
    store.add("comfortable cushioned shoes for easy running")
    store.add("outdoor trail shoes with rugged grip")
    store.add("lightweight training sneakers for speed work")
    store.add("comfortable lightweight shoes for easy walks")
    store.add("rugged outdoor trail running shoes")
    store.add("comfortable running shoes for everyday training")
    return store
}

// MARK: - Request / Response types

struct AddRequest: Content { let description: String }
struct SearchResult: Content { let rank: Int; let description: String; let similarity: Double }
