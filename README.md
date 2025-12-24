# Telegraf MongoDB Querier Input Plugin

A lightweight Go binary that executes MongoDB queries and outputs metrics in Telegraf-compatible JSON format. Designed to be used with Telegraf's `exec` input plugin to collect custom MongoDB metrics and send them to various outputs (ClickHouse, PostgreSQL, MySQL, etc.).

## Features

- **Environment Variable Based**: All configuration via environment variables (no config files needed)
- **MongoDB Query Support**: Run find queries with filter conditions
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
export QUERY_NAME="active_users"
export METRIC_TAGS="metric=users,source=mongodb"
export MONGO_QUERY='{"status":"active"}'

./mongo-telegraf-query
```

**Expected Output:**
```json
[
  {
    "field": {
      "_id": "ObjectID(\"507f1f77bcf86cd799439011\")",
      "name": "John",
      "status": "active",
      "age": 28
    },
    "tag": {
      "metric": "users",
      "source": "mongodb"
    },
    "timestamp": 1703260800
  },
  {
    "field": {
      "_id": "ObjectID(\"507f191e810c19729de860ea\")",
      "name": "Jane",
      "status": "active",
      "age": 32
    },
    "tag": {
      "metric": "users",
      "source": "mongodb"
    },
    "timestamp": 1703260800
  }
]
```

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGO_URI` | MongoDB connection string | `mongodb://user:pass@host:27017` |
| `MONGO_DATABASE` | Database name | `myapp` |
| `MONGO_COLLECTION` | Collection name | `users` |
| `MONGO_QUERY` | Query filter (JSON dictionary) | `{"status":"active"}` |

### Optional

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `QUERY_NAME` | Query identifier for logging | `mongo_query` | `user_stats` |
| `MONGO_PROJECTION` | Field projection (JSON dictionary) | `""` (all fields) | `{"_id":1,"name":1}` |
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
    "QUERY_NAME=active_users",
    "METRIC_TAGS=metric=users,source=mongodb",
    "MONGO_QUERY={\"status\":\"active\"}"
  ]
```

## MongoDB Query Examples

### Simple Query - All Documents
```bash
export MONGO_QUERY='{}'
```

### Filter by Status
```bash
export MONGO_QUERY='{"status":"active"}'
```

### Filter by Date Range
```bash
export MONGO_QUERY='{"created_at":{"$gte":"2024-01-01","$lt":"2024-12-31"}}'
```

### Complex Query with Multiple Conditions
```bash
export MONGO_QUERY='{"status":"active","region":"us-east","tier":{"$in":["premium","enterprise"]}}'
```

### Query with Regex
```bash
export MONGO_QUERY='{"email":{"$regex":"@example.com$"}}'
```

### Field Projection (Select Specific Fields)
```bash
# Select only _id and name fields
export MONGO_QUERY='{"status":"active"}'
export MONGO_PROJECTION='{"_id":1,"name":1}'
```

```bash
# Exclude specific fields (return all except password)
export MONGO_QUERY='{}'
export MONGO_PROJECTION='{"password":0,"internal_data":0}'
```

```bash
# Combine query and projection
export MONGO_QUERY='{"region":"us-west"}'
export MONGO_PROJECTION='{"_id":1,"name":1,"email":1}'
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
  -e MONGO_QUERY='{"status":"active"}' \
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

The binary outputs a **JSON array** containing all metrics (compatible with Telegraf's `data_format = "json"`):

```json
[
  {
    "field": {
      "_id": "ObjectID(\"507f1f77bcf86cd799439011\")",
      "name": "John",
      "status": "active",
      "age": 28,
      "score": 95.5
    },
    "tag": {
      "metric": "users",
      "source": "mongodb",
      "environment": "production"
    },
    "timestamp": 1703260800
  }
]
```

### Field vs Tag Logic

- **Fields**: ALL data returned from MongoDB query (`_id`, `name`, numeric values, strings, booleans, etc.)
- **Tags**: ONLY external metadata from `METRIC_TAGS` environment variable (blueprint, environment, source, etc.)
- **Nested Objects**: Flattened into fields with nested key names
- **Note**: The query uses MongoDB's `find()` operation, not aggregation pipelines

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
