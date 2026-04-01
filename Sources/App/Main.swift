// Copyright 2026 Wayne W Bishop. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Vapor

// Quiver Demo — Vapor Server
// Semantic search, price prediction, and product clustering
// running inside Vapor request handlers. One binary, swift run,
// zero external services. Runs on macOS and Linux.

@main
struct App {
    static func main() async throws {
        let app = try await Application.make()
        try routes(app)
        try await app.execute()
    }
}
