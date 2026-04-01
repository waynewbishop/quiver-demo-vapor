// Copyright 2026 Wayne W Bishop. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Vapor

// Request and response types — all Codable.
// The same [Double] that Vapor decodes from JSON is the same [Double]
// that Quiver computes on. No conversion, no wrapper types.

// MARK: - Similarity

struct SimilarityRequest: Content {
    let vectorA: [Double]
    let vectorB: [Double]
}

struct SimilarityResponse: Content {
    let similarity: Double
}

// MARK: - Search

struct SearchRequest: Content {
    let query: [Double]
    let catalog: [[Double]]
    let topK: Int
}

struct SearchResult: Content {
    let index: Int
    let score: Double
}

// MARK: - Classify

struct ClassifyRequest: Content {
    let trainingFeatures: [[Double]]
    let trainingLabels: [Int]
    let newSamples: [[Double]]
}

struct ClassifyResponse: Content {
    let predictions: [Int]
}
