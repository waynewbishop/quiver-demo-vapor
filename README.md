# Quiver Demo for Vapor

This demo mimics the functionality of a vector database. In production, vectors would be stored in SQLite, Postgres, or any data source — [Quiver](https://github.com/waynewbishop/quiver) handles all the pre and post data processing: similarity scoring, search ranking, classification, and feature scaling.

Most server-side ML requires bridging to a separate runtime. Quiver eliminates that bridge entirely. The `[Double]` that Vapor's `Codable` decodes from JSON is the same `[Double]` that Quiver computes on. No subprocess, no interprocess communication — the math runs inside the request handler with sub-millisecond overhead. Quiver extends Swift's Array type but does not shadow any properties or functions from Vapor or its dependencies.

## Run it

1. Clone this repo
2. `swift run`
3. Server starts on `http://localhost:8080`

## Endpoints

**POST /similarity** — Cosine similarity between two vectors. The operation that powers recommendation engines and duplicate detection, computed in microseconds.

**POST /search** — Batch cosine similarity against an entire catalog, returning the top-K matches. No vector index — Quiver computes directly on the arrays.

**POST /classify** — KNN classification on new data points using FeatureScaler for normalization. In production, the trained model would be loaded from Codable persistence rather than retrained per request.

## Quiver APIs used

- `cosineOfAngle(with:)` — pairwise vector similarity
- `cosineSimilarities(to:)` — batch similarity across a collection
- `topIndices(k:)` — top-K selection without sorting the full array
- `KNearestNeighbors.fit()`, `predict()` — classification in the request path
- `FeatureScaler.fit()`, `transform()` — normalizing multi-scale features

## Learn more

- [Quiver](https://github.com/waynewbishop/quiver) — the framework
- [Quiver Cookbook](https://github.com/waynewbishop/quiver-cookbook) — 42 interactive recipes
- [Quiver Documentation](https://waynewbishop.github.io/quiver/documentation/quiver/) — API reference and conceptual guides
- [Swift Algorithms & Data Structures](https://waynewbishop.github.io/swift-algorithms/) — the companion book
