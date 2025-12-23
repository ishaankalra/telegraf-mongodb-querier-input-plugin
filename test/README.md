# Test Scripts

This directory contains test scripts and utilities for testing the MongoDB Telegraf Querier plugin.

## Available Tests

### `test-local.sh`
Tests the binary against a local MongoDB instance.

**Requirements:**
- MongoDB running locally on `localhost:27017`
- Database: `usage_db` with collection `daily_token_usage`

**Usage:**
```bash
cd test
./test-local.sh
```

### `test-unit.sh` (Coming Soon)
Unit tests for the Go binary.

### `test-integration.sh` (Coming Soon)
Integration tests with Telegraf + ClickHouse.

## Running Tests

### Quick Test
```bash
# From repository root
make test
```

### Manual Test with Custom MongoDB
```bash
export MONGO_URI="mongodb://your-host:27017"
export MONGO_DATABASE="your_db"
export MONGO_COLLECTION="your_collection"
export MONGO_QUERY='{"status":"active"}'
export METRIC_TAGS="metric=test,source=mongodb"

./mongo-telegraf-query
```

## Test Data

If you need sample data for testing, you can insert test documents:

```javascript
// Connect to MongoDB
mongosh

use test_db

// Insert sample user data
db.users.insertMany([
  { status: "active", age: 25, region: "us-west", created_at: new Date() },
  { status: "active", age: 30, region: "us-east", created_at: new Date() },
  { status: "inactive", age: 35, region: "eu-west", created_at: new Date() },
  { status: "pending", age: 28, region: "us-west", created_at: new Date() }
])

// Verify data
db.users.find({ status: "active" })
```

Then test with:
```bash
export MONGO_URI="mongodb://localhost:27017"
export MONGO_DATABASE="test_db"
export MONGO_COLLECTION="users"
export MONGO_QUERY='{"status":"active"}'
export METRIC_TAGS="metric=users,source=test"

../mongo-telegraf-query
```

Example queries:
```bash
# All documents
export MONGO_QUERY='{}'

# Filter by status
export MONGO_QUERY='{"status":"active"}'

# Multiple filters
export MONGO_QUERY='{"status":"active","region":"us-west"}'
```
