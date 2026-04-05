// Copyright 2026 Wayne W Bishop. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Vapor
import Quiver

// Quiver Demo — Semantic Running Shoe Search
//
// This demo uses real running shoe names in a semantic search catalog.
// When a shoe is added, Quiver's text pipeline converts its description
// into a numeric vector. When a runner searches, Quiver compares the
// query vector against every shoe and ranks by meaning — not keywords.
//
// The embedding space has 6 dimensions that map to how runners think:
//   [weight, cushion, stability, durability, drop, terrain]

// MARK: - Embeddings

// Hypothetical word vectors (6 dimensions). Each dimension loosely
// maps to a shoe property. Words with similar implications point in
// similar directions — "carbon" and "fast" cluster together, "trail"
// and "grip" cluster together. In production, these would come from
// a trained language model.

//   dimensions: [weight, cushion, stability, durability, drop, terrain]
let embeddings: [String: [Double]] = [
    "lightweight": [0.1, 0.4, 0.0, 0.3, 0.5, 0.0],
    "light":       [0.1, 0.4, 0.0, 0.3, 0.5, 0.0],
    "fast":        [0.1, 0.4, 0.0, 0.2, 0.5, 0.0],
    "carbon":      [0.1, 0.5, 0.0, 0.1, 0.5, 0.0],
    "plate":       [0.1, 0.5, 0.0, 0.1, 0.5, 0.0],
    "race":        [0.1, 0.5, 0.0, 0.1, 0.5, 0.0],
    "super":       [0.1, 0.6, 0.0, 0.1, 0.5, 0.0],
    "cushioned":   [0.6, 0.9, 0.1, 0.8, 0.5, 0.0],
    "soft":        [0.6, 0.9, 0.1, 0.7, 0.5, 0.0],
    "bouncy":      [0.3, 0.6, 0.1, 0.6, 0.4, 0.0],
    "daily":       [0.5, 0.6, 0.2, 0.9, 0.5, 0.1],
    "trainer":     [0.5, 0.6, 0.2, 0.8, 0.5, 0.1],
    "long":        [0.5, 0.8, 0.1, 0.8, 0.5, 0.0],
    "run":         [0.4, 0.5, 0.1, 0.7, 0.5, 0.1],
    "shoe":        [0.5, 0.5, 0.2, 0.7, 0.5, 0.2],
    "recovery":    [0.7, 0.9, 0.1, 0.7, 0.5, 0.0],
    "stability":   [0.6, 0.6, 0.9, 0.8, 0.6, 0.0],
    "support":     [0.6, 0.6, 0.8, 0.8, 0.6, 0.0],
    "neutral":     [0.4, 0.5, 0.0, 0.7, 0.5, 0.1],
    "trail":       [0.5, 0.5, 0.1, 0.8, 0.4, 0.9],
    "grip":        [0.5, 0.4, 0.1, 0.8, 0.4, 0.9],
    "durable":     [0.6, 0.6, 0.2, 0.9, 0.5, 0.1],
    "reliable":    [0.5, 0.6, 0.2, 0.9, 0.5, 0.1],
    "tempo":       [0.3, 0.4, 0.1, 0.6, 0.4, 0.0],
    "road":        [0.4, 0.6, 0.1, 0.7, 0.5, 0.0],
    "smooth":      [0.5, 0.7, 0.1, 0.7, 0.5, 0.0],
    "plush":       [0.6, 0.9, 0.1, 0.7, 0.5, 0.0],
    "rugged":      [0.5, 0.3, 0.1, 0.9, 0.4, 0.9],
    "racer":       [0.1, 0.4, 0.0, 0.1, 0.5, 0.0],
]

// MARK: - Product store

// Each shoe is a description paired with its semantic vector.
// add() handles the full pipeline: tokenize → embed → meanVector.
final class ProductStore: @unchecked Sendable {
    var shoes: [(description: String, vector: [Double])] = []

    func add(_ description: String) {
        let tokens = description.tokenize()
        guard let vector = tokens.embed(using: embeddings).meanVector() else { return }
        shoes.append((description, vector))
    }

    func remove(_ description: String) -> Bool {
        guard let index = shoes.firstIndex(where: { $0.description == description }) else { return false }
        shoes.remove(at: index)
        return true
    }

    var descriptions: [String] { shoes.map(\.description) }

    func search(query: String, topK: Int = 3) -> [(rank: Int, label: String, score: Double)] {
        let tokens = query.tokenize()
        guard let queryVector = tokens.embed(using: embeddings).meanVector() else { return [] }
        return shoes.map(\.vector)
            .cosineSimilarities(to: queryVector)
            .topIndices(k: topK, labels: descriptions)
    }
}

// MARK: - Seed data

// 15 real running shoes across 6 categories. Descriptions use
// runner language — every runner will recognize these names.
func seededStore() -> ProductStore {
    let store = ProductStore()

    // Super shoes — carbon plate racers for race day
    store.add("Nike Vaporfly 3 — super fast carbon plate racer")
    store.add("New Balance SC Elite v5 — race day carbon plate super shoe")
    store.add("ASICS Metaspeed Sky+ — fast light carbon plate racer")

    // Daily trainers — the shoes runners wear most
    store.add("Nike Pegasus 41 — reliable durable road trainer")
    store.add("Adidas EVO SL — smooth reliable road shoe")
    store.add("ASICS Novablast 4 — bouncy soft daily shoe")
    store.add("Brooks Ghost 16 — durable neutral road trainer")
    store.add("Hoka Clifton 9 — soft light daily shoe")

    // Long run and recovery
    store.add("New Balance 1080v14 — plush soft shoe for long run")
    store.add("Nike Invincible 3 — soft cushioned recovery shoe")

    // Stability
    store.add("Brooks Adrenaline GTS 24 — stability support shoe")

    // Trail
    store.add("Hoka Speedgoat 6 — rugged trail shoe with grip")
    store.add("Salomon Ultra Glide 2 — soft trail run shoe")

    // Tempo
    store.add("Saucony Kinvara 15 — fast light tempo trainer")

    return store
}

// MARK: - Request / Response

struct AddRequest: Content { let description: String }
struct SearchResult: Content { let rank: Int; let description: String; let similarity: Double }
