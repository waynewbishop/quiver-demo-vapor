// Copyright 2026 Wayne W Bishop. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Vapor

// Quiver Demo for Vapor
// The [Double] that Codable decodes from JSON is the same [Double]
// that Quiver computes on. No serialization boundary, no bridge
// to another runtime. The server doesn't call a math service — it IS
// the math service. This runs on Linux with zero Apple dependencies.

// Quiver extends Swift's Array type but does not shadow any properties
// or functions from Vapor, Fluent, or their dependencies. Element-wise
// operators were replaced with named methods (.add(), .subtract()) to
// avoid conflicts with stdlib concatenation. Quiver is purely additive.

@main
struct App {
    static func main() async throws {
        let app = try await Application.make()
        try routes(app)
        try await app.execute()
    }
}
