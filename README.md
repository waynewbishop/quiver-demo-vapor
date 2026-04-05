# Quiver Demo for Vapor

Most shoe finders match keywords — searching "cushioned long run shoe"
only finds results containing those exact words. Semantic search matches
meaning instead, so a query finds the New Balance 1080 and Nike
Invincible even when the descriptions use different words — because
the concepts are similar.

This demo uses [Quiver](https://github.com/waynewbishop/quiver) to add
semantic search to a Vapor server. The catalog contains 14 real running
shoes that every runner will recognize. When added, each shoe's
description is automatically converted to a numeric vector using
Quiver's `tokenize()` → `embed(using:)` → `meanVector()` pipeline.
When searched, Quiver's `cosineSimilarities()` ranks every shoe by
meaning. Four CRUD endpoints, zero external services.

## Run it

```bash
swift run
```

Server starts on `http://localhost:8080`.

## Endpoints

**List all shoes:**

```bash
curl -s localhost:8080/products | jq
```

**Add a shoe** (Quiver tokenizes and embeds it automatically):

```bash
curl -s localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"description": "Puma Deviate Nitro Elite 4 — light carbon race super shoe"}' \
  -w "%{http_code}"
```

**Search by meaning:**

```bash
curl -s "localhost:8080/search?q=cushioned+long+run+shoe" | jq
```

```json
[
  {"rank": 1, "description": "New Balance 1080v14 — soft cushioned long run shoe", "similarity": 0.999},
  {"rank": 2, "description": "Hoka Clifton 9 — lightweight cushioned daily shoe", "similarity": 0.998},
  {"rank": 3, "description": "Adidas EVO SL — smooth daily road trainer", "similarity": 0.998}
]
```

The `[Double]` that Vapor decodes from JSON is the same `[Double]` that
Quiver computes on. No serialization boundary, no subprocess, no second
runtime.

**More searches to try:**

```bash
curl -s "localhost:8080/search?q=light+carbon+race+shoe" | jq
curl -s "localhost:8080/search?q=stability+support" | jq
curl -s "localhost:8080/search?q=trail+grip" | jq
curl -s "localhost:8080/search?q=fast+tempo+shoe" | jq
curl -s "localhost:8080/search?q=soft+recovery+shoe" | jq
```

**Remove a shoe:**

```bash
curl -s -X DELETE "localhost:8080/products/Saucony%20Kinvara%2015%20%E2%80%94%20light%20fast%20tempo%20trainer"
```

## Quiver APIs used

- `tokenize()` — split text into clean lowercase tokens
- `embed(using:)` — look up word vectors from an embedding dictionary
- `meanVector()` — average word vectors into a single document vector
- `cosineSimilarities(to:)` — rank every shoe by similarity to the query
- `topIndices(k:labels:)` — return the best matches with rank and score

## Learn more

- [Quiver](https://github.com/waynewbishop/quiver) — the framework
- [Quiver Cookbook](https://github.com/waynewbishop/quiver-cookbook) — interactive recipes
- [Quiver Documentation](https://waynewbishop.github.io/quiver/documentation/quiver/) — API reference and conceptual guides
- [Swift Algorithms & Data Structures](https://waynewbishop.github.io/swift-algorithms/) — the companion book
