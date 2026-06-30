# Quiver Demo for Vapor

Most shoe finders match keywords — searching "cushioned long run shoe"
only finds results containing those exact words. Semantic search matches
meaning instead, so a query finds the New Balance 1080 and Nike
Invincible even when the descriptions use different words — because
the concepts are similar.

This demo uses [Quiver](https://github.com/waynewbishop/quiver) to add
semantic search to a Vapor server. The catalog contains 14 real running
shoes that every runner will recognize. Each shoe's description is turned
into a numeric vector by an `Embedder` — Quiver's contract for converting
text to a vector, here backed by a word-vector table — and stored in an
`EmbeddingIndex`, Quiver's on-device vector store. When a runner searches,
`index.retrieve(query, k:)` embeds the query and ranks every shoe by
meaning in one call. Swapping the word-vector table for an on-device
sentence model later changes only the embedder; the routes stay as
written. Four CRUD endpoints, zero external services.

This `/search` route is the retrieval half of a RAG pipeline: it finds the
most relevant catalog entries for a query. A language model, fed those
results as context, would supply the generation half — but Quiver's role
is the retrieval, and the demo stops there.

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
{
  "results": [
    {"rank": 1, "description": "ASICS Novablast 4 — bouncy soft daily shoe", "similarity": 0.9997, "zScore": 0.75},
    {"rank": 2, "description": "New Balance 1080v14 — plush soft shoe for long run", "similarity": 0.9989, "zScore": 0.74},
    {"rank": 3, "description": "Adidas EVO SL — smooth reliable road shoe", "similarity": 0.9984, "zScore": 0.73}
  ],
  "stats": {
    "catalogSize": 14,
    "mean": 0.9476,
    "standardDeviation": 0.0697
  }
}
```

A raw similarity of 0.9997 is hard to interpret on its own. The same
hit expressed as a z-score above the catalog mean tells callers whether
the top match is well-separated from the rest of the catalog or just
barely above the crowd. One call carries it all: `index.retrieve(query, k:)`
returns a `RetrievalResult` with the ranked `hits`, the full score field,
and its `mean` and `standardDeviation` already computed — so each hit's
z-score is read straight off the result, nothing recomputed by hand.

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

- `Embedder` — the contract for turning text into a vector; the demo's `ShoeEmbedder` conforms by averaging word vectors
- `tokenize()` — split text into clean lowercase tokens
- `embed(using:)` — look up word vectors from an embedding dictionary
- `meanVector()` — average word vectors into a single document vector
- `EmbeddingIndex` — the on-device vector store; `add(_:label:)` embeds each shoe once at ingest, `retrieve(_:k:)` ranks a query against the whole catalog in one call
- `RetrievalResult` — the outcome of a retrieval: ranked `hits` (rank, label, score) plus the full score field with its `mean` and `standardDeviation` already computed
- `zScore(of:)` — express a hit's similarity as standard deviations above the catalog mean, so callers see separation, not just a raw score

## Learn more

- [Quiver](https://github.com/waynewbishop/quiver) — the framework
- [Quiver Cookbook](https://github.com/waynewbishop/quiver-cookbook) — interactive recipes
- [Quiver Documentation](https://waynewbishop.github.io/quiver/documentation/quiver/) — API reference and conceptual guides
- [Swift Algorithms & Data Structures](https://waynewbishop.github.io/swift-algorithms/) — the companion book
