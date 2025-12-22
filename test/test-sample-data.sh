#!/bin/bash
# Create sample test data in MongoDB for testing

set -e

echo "📝 Creating sample test data in MongoDB"
echo "========================================"
echo ""

MONGO_HOST="${MONGO_HOST:-localhost:27017}"
TEST_DB="${TEST_DB:-test_db}"

echo "Target: mongodb://$MONGO_HOST/$TEST_DB"
echo ""

# Create sample users collection
echo "Creating sample users..."
mongosh "mongodb://$MONGO_HOST/$TEST_DB" --quiet --eval '
db.users.deleteMany({});
db.users.insertMany([
  { user_id: "user1", status: "active", age: 25, region: "us-west", created_at: new Date() },
  { user_id: "user2", status: "active", age: 30, region: "us-east", created_at: new Date() },
  { user_id: "user3", status: "active", age: 28, region: "us-west", created_at: new Date() },
  { user_id: "user4", status: "inactive", age: 35, region: "eu-west", created_at: new Date() },
  { user_id: "user5", status: "inactive", age: 32, region: "us-east", created_at: new Date() },
  { user_id: "user6", status: "pending", age: 22, region: "us-west", created_at: new Date() }
]);
print("✅ Created " + db.users.countDocuments({}) + " users");
'

# Create sample orders collection
echo "Creating sample orders..."
mongosh "mongodb://$MONGO_HOST/$TEST_DB" --quiet --eval '
db.orders.deleteMany({});
db.orders.insertMany([
  { order_id: "ord1", user_id: "user1", status: "completed", region: "us-west", amount: 150.50, items: 3, created_at: new Date() },
  { order_id: "ord2", user_id: "user2", status: "completed", region: "us-east", amount: 250.00, items: 5, created_at: new Date() },
  { order_id: "ord3", user_id: "user1", status: "completed", region: "us-west", amount: 89.99, items: 2, created_at: new Date() },
  { order_id: "ord4", user_id: "user3", status: "pending", region: "us-west", amount: 320.00, items: 4, created_at: new Date() },
  { order_id: "ord5", user_id: "user4", status: "cancelled", region: "eu-west", amount: 45.00, items: 1, created_at: new Date() }
]);
print("✅ Created " + db.orders.countDocuments({}) + " orders");
'

# Create sample products collection
echo "Creating sample products..."
mongosh "mongodb://$MONGO_HOST/$TEST_DB" --quiet --eval '
db.products.deleteMany({});
db.products.insertMany([
  { product_id: "prod1", name: "Laptop", category: "electronics", price: 999.99, quantity: 50, in_stock: true },
  { product_id: "prod2", name: "Mouse", category: "electronics", price: 29.99, quantity: 200, in_stock: true },
  { product_id: "prod3", name: "T-Shirt", category: "clothing", price: 19.99, quantity: 150, in_stock: true },
  { product_id: "prod4", name: "Jeans", category: "clothing", price: 59.99, quantity: 80, in_stock: true },
  { product_id: "prod5", name: "Desk", category: "furniture", price: 299.99, quantity: 10, in_stock: true }
]);
print("✅ Created " + db.products.countDocuments({}) + " products");
'

echo ""
echo "✅ Sample data created successfully!"
echo ""
echo "You can now test with queries like:"
echo ""
echo "# User stats by status"
echo "export MONGO_DATABASE=\"$TEST_DB\""
echo "export MONGO_COLLECTION=\"users\""
echo "export MONGO_QUERY='[{\"\\$group\":{\"_id\":\"\\$status\",\"count\":{\"\\$sum\":1},\"avg_age\":{\"\\$avg\":\"\\$age\"}}}]'"
echo ""
echo "# Order totals by region and status"
echo "export MONGO_COLLECTION=\"orders\""
echo "export MONGO_QUERY='[{\"\\$group\":{\"_id\":{\"region\":\"\\$region\",\"status\":\"\\$status\"},\"total_amount\":{\"\\$sum\":\"\\$amount\"},\"order_count\":{\"\\$sum\":1}}}]'"
echo ""
echo "# Product inventory by category"
echo "export MONGO_COLLECTION=\"products\""
echo "export MONGO_QUERY='[{\"\\$group\":{\"_id\":\"\\$category\",\"total_items\":{\"\\$sum\":\"\\$quantity\"},\"avg_price\":{\"\\$avg\":\"\\$price\"}}}]'"
