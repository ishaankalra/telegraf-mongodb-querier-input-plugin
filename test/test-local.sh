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

echo "📊 Test 1: All Token Usage Records"
echo "-----------------------------------"
export MONGO_URI="mongodb://localhost:27017"
export MONGO_DATABASE="usage_db"
export MONGO_COLLECTION="daily_token_usage"
export QUERY_NAME="all_token_usage"
export METRIC_TAGS="metric=tokens,source=mongodb,test=local"
export MONGO_QUERY='{}'

./mongo-telegraf-query | head -3
echo ""

echo "📊 Test 2: Filter by Model Name"
echo "-----------------------------------"
export QUERY_NAME="sonnet_usage"
export METRIC_TAGS="metric=tokens,source=mongodb,test=local,model=sonnet"
export MONGO_QUERY='{"model_name":"claude-sonnet-4-5-20250929"}'

./mongo-telegraf-query | head -3
echo ""

echo "📊 Test 3: Filter by User ID"
echo "-----------------------------------"
export QUERY_NAME="facets_user_usage"
export METRIC_TAGS="metric=tokens,source=mongodb,test=local,user=facets"
export MONGO_QUERY='{"user_id":"127-facets.cloud"}'

./mongo-telegraf-query
echo ""

echo "📊 Test 4: Filter by Agent Type and User"
echo "-----------------------------------"
export QUERY_NAME="anthropic_facets_usage"
export METRIC_TAGS="metric=tokens,source=mongodb,test=local"
export MONGO_QUERY='{"agent_type":"anthropic","user_id":"127-facets.cloud"}'

./mongo-telegraf-query
echo ""

echo "✅ All tests completed successfully!"
