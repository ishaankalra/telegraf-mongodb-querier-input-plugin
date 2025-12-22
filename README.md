# Telegraf MongoDB Querier Input Plugin

A lightweight Go binary that executes MongoDB aggregation queries and outputs metrics in Telegraf-compatible JSON format. Designed to be used with Telegraf's `exec` input plugin to collect custom MongoDB metrics and send them to various outputs (ClickHouse, PostgreSQL, MySQL, etc.).

## Features

- **Environment Variable Based**: All configuration via environment variables (no config files needed)
- **MongoDB Aggregation Support**: Run complex aggregation pipelines
- **Telegraf Compatible**: Outputs newline-delimited JSON metrics
- **Flexible Tagging**: Add custom tags to metrics via `METRIC_TAGS`
- **Multiple Queries**: Run multiple queries with separate `exec` blocks
- **Cloud Native**: Docker image with Telegraf + custom binary

## Quick Start

### 1. Build the Binary

```bash
cd /Users/ishaankalra/Documents/Facets\ Work/github-repositories/telegraf-mongodb-querier-input-plugin
make build
```

### 2. Test Locally

Set environment variables and run:

```bash
export MONGO_URI="mongodb://localhost:27017"
export MONGO_DATABASE="myapp"
export MONGO_COLLECTION="users"
export QUERY_NAME="user_stats"
export METRIC_TAGS="metric=users,source=mongodb"
export MONGO_QUERY='[{"$group":{"_id":"$status","count":{"$sum":1}}}]'

./mongo-telegraf-query
```

**Expected Output:**
```json
{"fields":{"count":150},"tags":{"metric":"users","source":"mongodb","_id":"active"},"timestamp":1703260800}
{"fields":{"count":45},"tags":{"metric":"users","source":"mongodb","_id":"inactive"},"timestamp":1703260800}
```

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGO_URI` | MongoDB connection string | `mongodb://user:pass@host:27017` |
| `MONGO_DATABASE` | Database name | `myapp` |
| `MONGO_COLLECTION` | Collection name | `users` |
| `MONGO_QUERY` | Aggregation pipeline (JSON array) | `[{"$group":{"_id":"$status","count":{"$sum":1}}}]` |

### Optional

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `QUERY_NAME` | Query identifier for logging | `mongo_query` | `user_stats` |
| `METRIC_TAGS` | Comma-separated tags (key=value) | `""` | `metric=users,env=prod,source=mongodb` |

## Telegraf Configuration

### Example with SQL Output (ClickHouse)

```toml
[agent]
  interval = "60s"

# SQL Output to ClickHouse
[[outputs.sql]]
  driver = "clickhouse"
  data_source_name = "clickhouse://${CLICKHOUSE_HOST}:9000?username=${CLICKHOUSE_USER}&password=${CLICKHOUSE_PASSWORD}&database=telegraf"
  table_template = "mongo_metrics"
  timestamp_column = "timestamp"

# MongoDB Query: User Statistics
[[inputs.exec]]
  commands = ["/usr/local/bin/mongo-telegraf-query"]
  timeout = "30s"
  data_format = "json"

  environment = [
    "MONGO_URI=${MONGO_URI}",
    "MONGO_DATABASE=myapp",
    "MONGO_COLLECTION=users",
    "QUERY_NAME=user_stats",
    "METRIC_TAGS=metric=users,source=mongodb",
    "MONGO_QUERY=[{\"$group\":{\"_id\":\"$status\",\"user_count\":{\"$sum\":1},\"avg_age\":{\"$avg\":\"$age\"}}}]"
  ]
```

## MongoDB Query Examples

### Simple Aggregation
```bash
export MONGO_QUERY='[{"$group":{"_id":"$status","count":{"$sum":1}}}]'
```

### With Match Filter
```bash
export MONGO_QUERY='[{"$match":{"created_at":{"$gte":"2024-01-01"}}},{"$group":{"_id":"$region","total":{"$sum":"$amount"}}}]'
```

### Complex Pipeline
```bash
export MONGO_QUERY='[
  {"$match":{"status":"active"}},
  {"$group":{
    "_id":{"region":"$region","tier":"$tier"},
    "user_count":{"$sum":1},
    "avg_revenue":{"$avg":"$revenue"}
  }},
  {"$sort":{"user_count":-1}},
  {"$limit":10}
]'
```

## Docker Usage

### Build Image

```bash
make docker-build
```

### Run Container

```bash
docker run --rm \
  -e MONGO_URI="mongodb://host.docker.internal:27017" \
  -e MONGO_DATABASE="myapp" \
  -e MONGO_COLLECTION="users" \
  -e MONGO_QUERY='[{"$group":{"_id":"$status","count":{"$sum":1}}}]' \
  -e METRIC_TAGS="metric=users,source=mongodb" \
  telegraf-mongodb-querier:latest \
  /usr/local/bin/mongo-telegraf-query
```

## Kubernetes Deployment

See `k8s/` directory for example manifests:

- `configmap-telegraf.yaml` - Telegraf configuration
- `deployment.yaml` - Kubernetes deployment (coming soon)
- `secrets.yaml` - MongoDB and ClickHouse credentials (coming soon)

## Output Format

The binary outputs newline-delimited JSON metrics:

```json
{"fields":{"user_count":150,"avg_age":28.5},"tags":{"status":"active","metric":"users"},"timestamp":1703260800}
```

### Field vs Tag Logic

- **Fields** (numeric measurements): `int`, `float`, `bool`
- **Tags** (dimensions): `string` values
- **Nested Objects**: Flattened into tags/fields based on type

## Development

### Build

```bash
make build
```

### Test

#### Unit Tests
```bash
make test
```

#### Integration Tests (Local MongoDB)
```bash
# Test with your existing local MongoDB data
make test-local

# Create sample data and run comprehensive tests
make test-sample-data
```

See the [test directory](./test/) for more testing options and documentation.

### Clean

```bash
make clean
```

## Use Cases

- Collect custom business metrics from MongoDB
- Monitor collection sizes and growth
- Track user activity and engagement
- Analyze order and revenue trends
- Export MongoDB aggregations to analytical databases

## License

MIT

## Contributing

Contributions welcome! Please open an issue or PR.
