#!/bin/bash
# Test the binary with sample data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🧪 Testing MongoDB Telegraf Querier with Sample Data"
echo "====================================================="
echo ""

# Check if binary exists
if [ ! -f "$REPO_ROOT/mongo-telegraf-query" ]; then
    echo "❌ Binary not found. Building..."
    cd "$REPO_ROOT"
    make build
    echo "✅ Binary built successfully"
    echo ""
fi

# Set up environment
export MONGO_URI="${MONGO_URI:-mongodb://localhost:27017}"
export MONGO_DATABASE="${MONGO_DATABASE:-test_db}"

# Test 1: Active Users
echo "📊 Test 1: Active Users"
echo "-----------------------------------"
export MONGO_COLLECTION="users"
export QUERY_NAME="active_users"
export METRIC_TAGS="metric=users,source=mongodb,test=sample_data,status=active"
export MONGO_QUERY='{"status":"active"}'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 2: Users in US West Region
echo "📊 Test 2: Users in US West Region"
echo "-----------------------------------"
export QUERY_NAME="us_west_users"
export METRIC_TAGS="metric=users,source=mongodb,test=sample_data,region=us-west"
export MONGO_QUERY='{"region":"us-west"}'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 3: Completed Orders
echo "📊 Test 3: Completed Orders"
echo "-----------------------------------"
export MONGO_COLLECTION="orders"
export QUERY_NAME="completed_orders"
export METRIC_TAGS="metric=orders,source=mongodb,test=sample_data,status=completed"
export MONGO_QUERY='{"status":"completed"}'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 4: Completed Orders from US West
echo "📊 Test 4: Completed Orders from US West"
echo "-----------------------------------"
export QUERY_NAME="us_west_completed_orders"
export METRIC_TAGS="metric=orders,source=mongodb,test=sample_data"
export MONGO_QUERY='{"status":"completed","region":"us-west"}'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 5: Electronics Products
echo "📊 Test 5: Electronics Products"
echo "-----------------------------------"
export MONGO_COLLECTION="products"
export QUERY_NAME="electronics_products"
export METRIC_TAGS="metric=products,source=mongodb,test=sample_data,category=electronics"
export MONGO_QUERY='{"category":"electronics"}'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 6: All Users (No Filter)
echo "📊 Test 6: All Users (No Filter)"
echo "-----------------------------------"
export MONGO_COLLECTION="users"
export QUERY_NAME="all_users"
export METRIC_TAGS="metric=users,source=mongodb,test=sample_data"
export MONGO_QUERY='{}'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 7: Projection - Select Specific Fields
echo "📊 Test 7: Active Users with Field Projection"
echo "-----------------------------------"
export QUERY_NAME="active_users_projection"
export METRIC_TAGS="metric=users,source=mongodb,test=sample_data,projection=enabled"
export MONGO_QUERY='{"status":"active"}'
export MONGO_PROJECTION='{"user_id":1,"status":1,"age":1}'

"$REPO_ROOT/mongo-telegraf-query"
echo ""
echo "Note: Only user_id, status, and age fields are returned"
echo ""

echo "✅ All tests completed successfully!"
