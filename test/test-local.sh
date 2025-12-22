#!/bin/bash
# Test script for local MongoDB testing

set -e

echo "🧪 Testing MongoDB Telegraf Querier Plugin"
echo "==========================================="
echo ""

# Check if binary exists
if [ ! -f "./mongo-telegraf-query" ]; then
    echo "❌ Binary not found. Building..."
    make build
    echo "✅ Binary built successfully"
fi

echo "📊 Test 1: Token Usage by Model"
echo "-----------------------------------"
export MONGO_URI="mongodb://localhost:27017"
export MONGO_DATABASE="usage_db"
export MONGO_COLLECTION="daily_token_usage"
export QUERY_NAME="token_usage_by_model"
export METRIC_TAGS="metric=tokens,source=mongodb,test=local"
export MONGO_QUERY='[{"$group":{"_id":"$model_name","total_tokens":{"$sum":"$total_tokens"},"total_cost":{"$sum":"$cost_usd"},"record_count":{"$sum":1}}}]'

./mongo-telegraf-query
echo ""

echo "📊 Test 2: Usage by User and Agent Type"
echo "-----------------------------------"
export QUERY_NAME="usage_by_user_agent"
export METRIC_TAGS="metric=usage,source=mongodb,test=local"
export MONGO_QUERY='[{"$group":{"_id":{"user":"$user_id","agent":"$agent_type"},"total_tokens":{"$sum":"$total_tokens"},"total_cost":{"$sum":"$cost_usd"},"avg_daily_cost":{"$avg":"$cost_usd"}}}]'

./mongo-telegraf-query
echo ""

echo "📊 Test 3: Daily Totals with Date Filtering"
echo "-----------------------------------"
export QUERY_NAME="daily_totals"
export METRIC_TAGS="metric=daily_stats,source=mongodb,test=local"
export MONGO_QUERY='[{"$match":{"usage_date":{"$gte":{"$date":"2025-11-01T00:00:00Z"}}}},{"$group":{"_id":{"$dateToString":{"format":"%Y-%m-%d","date":"$usage_date"}},"total_tokens":{"$sum":"$total_tokens"},"total_cost":{"$sum":"$cost_usd"},"unique_users":{"$addToSet":"$user_id"}}},{"$project":{"_id":1,"total_tokens":1,"total_cost":1,"user_count":{"$size":"$unique_users"}}},{"$sort":{"_id":-1}},{"$limit":5}]'

./mongo-telegraf-query
echo ""

echo "✅ All tests completed successfully!"
