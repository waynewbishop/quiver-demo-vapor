# quiver-demo-vapor

Most search features match keywords — "running shoes" only finds results
containing those exact words. Semantic search matches meaning instead,
so "comfortable running shoes" finds "cushioned shoes for easy walks"
because the concepts are similar even when the words are different.

This demo uses [Quiver](https://github.com/waynewbishop/quiver) to add
semantic search to a Vapor server. Products are stored as text
descriptions. When added, each description is automatically converted
to a numeric vector using Quiver's `tokenize()` → `embed(using:)` →
`meanVector()` pipeline. When searched, Quiver's `cosineSimilarities()`
ranks every product by meaning. Four CRUD endpoints, zero external
services.

## Run it

```bash
swift run
```

Server starts on `http://localhost:8080`.

## Endpoints

**List products:**

```bash
curl -s localhost:8080/products | jq
```

**Add a product** (Quiver tokenizes and embeds it automatically):

```bash
curl -s localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"description": "durable waterproof trail shoes"}' -w "%{http_code}"
```

**Search by meaning** — finds products with similar concepts, not just matching words:

```bash
curl -s "localhost:8080/search?q=comfortable+running+shoes" | jq
```

```json
[
  {"rank": 1, "description": "comfortable cushioned shoes for easy running", "similarity": 0.99},
  {"rank": 2, "description": "comfortable running shoes for everyday training", "similarity": 0.98},
  {"rank": 3, "description": "comfortable lightweight shoes for easy walks", "similarity": 0.97}
]
```

The `[Double]` that Vapor decodes from JSON is the same `[Double]` that
Quiver computes on. No serialization boundary, no subprocess, no second
runtime.

**Remove a product:**

```bash
curl -s -X DELETE "localhost:8080/products/comfortable%20lightweight%20shoes%20for%20easy%20walks"
```

## Quiver APIs used

- `tokenize()` — split text into clean lowercase tokens
- `embed(using:)` — look up word vectors from an embedding dictionary
- `meanVector()` — average word vectors into a single document vector
- `cosineSimilarities(to:)` — rank every product by similarity to the query
- `topIndices(k:labels:)` — return the best matches with rank and score

## Learn more

- [Quiver](https://github.com/waynewbishop/quiver) — the framework
- [Quiver Cookbook](https://github.com/waynewbishop/quiver-cookbook) — 41 interactive recipes
- [Quiver Documentation](https://waynewbishop.github.io/quiver/documentation/quiver/) — API reference and conceptual guides
- [Swift Algorithms & Data Structures](https://waynewbishop.github.io/swift-algorithms/) — the companion book
