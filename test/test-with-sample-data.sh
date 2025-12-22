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

# Test 1: User Statistics
echo "📊 Test 1: User Statistics by Status"
echo "-----------------------------------"
export MONGO_COLLECTION="users"
export QUERY_NAME="user_stats_by_status"
export METRIC_TAGS="metric=users,source=mongodb,test=sample_data"
export MONGO_QUERY='[{"$group":{"_id":"$status","user_count":{"$sum":1},"avg_age":{"$avg":"$age"}}},{"$sort":{"user_count":-1}}]'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 2: User Statistics by Region
echo "📊 Test 2: User Statistics by Region"
echo "-----------------------------------"
export QUERY_NAME="user_stats_by_region"
export MONGO_QUERY='[{"$group":{"_id":"$region","user_count":{"$sum":1},"avg_age":{"$avg":"$age"}}}]'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 3: Order Totals by Status and Region
echo "📊 Test 3: Order Totals by Status and Region"
echo "-----------------------------------"
export MONGO_COLLECTION="orders"
export QUERY_NAME="order_totals"
export METRIC_TAGS="metric=orders,source=mongodb,test=sample_data"
export MONGO_QUERY='[{"$group":{"_id":{"status":"$status","region":"$region"},"total_amount":{"$sum":"$amount"},"order_count":{"$sum":1},"avg_order_value":{"$avg":"$amount"}}}]'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 4: Product Inventory by Category
echo "📊 Test 4: Product Inventory by Category"
echo "-----------------------------------"
export MONGO_COLLECTION="products"
export QUERY_NAME="product_inventory"
export METRIC_TAGS="metric=inventory,source=mongodb,test=sample_data"
export MONGO_QUERY='[{"$group":{"_id":"$category","total_items":{"$sum":"$quantity"},"product_count":{"$sum":1},"avg_price":{"$avg":"$price"},"total_value":{"$sum":{"$multiply":["$quantity","$price"]}}}}]'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

# Test 5: Complex Query - Top Spending Regions
echo "📊 Test 5: Top Spending Regions (with filtering and sorting)"
echo "-----------------------------------"
export MONGO_COLLECTION="orders"
export QUERY_NAME="top_spending_regions"
export METRIC_TAGS="metric=regional_sales,source=mongodb,test=sample_data"
export MONGO_QUERY='[{"$match":{"status":"completed"}},{"$group":{"_id":"$region","total_revenue":{"$sum":"$amount"},"order_count":{"$sum":1}}},{"$sort":{"total_revenue":-1}},{"$limit":3}]'

"$REPO_ROOT/mongo-telegraf-query"
echo ""

echo "✅ All tests completed successfully!"
