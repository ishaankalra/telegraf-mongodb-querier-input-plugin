package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Config represents the query configuration from environment variables
type Config struct {
	Name       string
	MongoURI   string
	Database   string
	Collection string
	Query      bson.M
	Projection bson.M
	Tags       map[string]string
}

// TelegrafMetric represents the output format for Telegraf
type TelegrafMetric struct {
	Fields    map[string]interface{} `json:"fields"`
	Tags      map[string]string      `json:"tags"`
	Timestamp int64                  `json:"timestamp"`
}

func main() {
	// Load configuration from environment variables
	config, err := loadConfigFromEnv()
	if err != nil {
		log.Fatalf("Failed to load config from environment: %v", err)
	}

	// Execute query and output metrics
	if err := executeQuery(config); err != nil {
		log.Fatalf("Failed to execute query: %v", err)
	}
}

// loadConfigFromEnv reads configuration from environment variables
func loadConfigFromEnv() (*Config, error) {
	config := &Config{
		Tags: make(map[string]string),
	}

	// Required: MongoDB URI
	config.MongoURI = os.Getenv("MONGO_URI")
	if config.MongoURI == "" {
		return nil, fmt.Errorf("MONGO_URI environment variable is required")
	}

	// Required: Database name
	config.Database = os.Getenv("MONGO_DATABASE")
	if config.Database == "" {
		return nil, fmt.Errorf("MONGO_DATABASE environment variable is required")
	}

	// Required: Collection name
	config.Collection = os.Getenv("MONGO_COLLECTION")
	if config.Collection == "" {
		return nil, fmt.Errorf("MONGO_COLLECTION environment variable is required")
	}

	// Required: Query (MongoDB query as JSON dictionary)
	queryJSON := os.Getenv("MONGO_QUERY")
	if queryJSON == "" {
		return nil, fmt.Errorf("MONGO_QUERY environment variable is required")
	}

	// Parse the query dictionary
	var query bson.M
	if err := json.Unmarshal([]byte(queryJSON), &query); err != nil {
		return nil, fmt.Errorf("failed to parse MONGO_QUERY as JSON dictionary: %w", err)
	}
	config.Query = query

	// Optional: Projection (field selection)
	projectionJSON := os.Getenv("MONGO_PROJECTION")
	if projectionJSON != "" {
		var projection bson.M
		if err := json.Unmarshal([]byte(projectionJSON), &projection); err != nil {
			return nil, fmt.Errorf("failed to parse MONGO_PROJECTION as JSON dictionary: %w", err)
		}
		config.Projection = projection
	}

	// Optional: Query name for logging
	config.Name = os.Getenv("QUERY_NAME")
	if config.Name == "" {
		config.Name = "mongo_query"
	}

	// Optional: Parse tags from METRIC_TAGS environment variable
	// Format: key1=value1,key2=value2
	if tagsStr := os.Getenv("METRIC_TAGS"); tagsStr != "" {
		tags := parseTags(tagsStr)
		config.Tags = tags
	}

	return config, nil
}

// parseTags parses a comma-separated key=value string into a map
// Example: "environment=prod,source=mongodb,metric=users" -> map[environment:prod source:mongodb metric:users]
func parseTags(tagsStr string) map[string]string {
	tags := make(map[string]string)
	pairs := strings.Split(tagsStr, ",")

	for _, pair := range pairs {
		kv := strings.SplitN(strings.TrimSpace(pair), "=", 2)
		if len(kv) == 2 {
			key := strings.TrimSpace(kv[0])
			value := strings.TrimSpace(kv[1])
			if key != "" {
				tags[key] = value
			}
		}
	}

	return tags
}

// executeQuery connects to MongoDB, runs the query, and outputs Telegraf metrics
func executeQuery(config *Config) error {
	// Create MongoDB client
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clientOpts := options.Client().ApplyURI(config.MongoURI)
	client, err := mongo.Connect(ctx, clientOpts)
	if err != nil {
		return fmt.Errorf("failed to connect to MongoDB: %w", err)
	}
	defer func() {
		if err := client.Disconnect(context.Background()); err != nil {
			log.Printf("Warning: failed to disconnect from MongoDB: %v", err)
		}
	}()

	// Ping to verify connection
	if err := client.Ping(ctx, nil); err != nil {
		return fmt.Errorf("failed to ping MongoDB: %w", err)
	}

	// Get collection
	collection := client.Database(config.Database).Collection(config.Collection)

	// Execute find query with optional projection
	opts := options.Find()
	if config.Projection != nil {
		opts.SetProjection(config.Projection)
	}

	cursor, err := collection.Find(ctx, config.Query, opts)
	if err != nil {
		return fmt.Errorf("failed to execute query: %w", err)
	}
	defer cursor.Close(ctx)

	// Process results and output metrics
	timestamp := time.Now().Unix()
	metricsCount := 0

	for cursor.Next(ctx) {
		var result bson.M
		if err := cursor.Decode(&result); err != nil {
			log.Printf("Warning: failed to decode result: %v", err)
			continue
		}

		// Convert MongoDB result to Telegraf metric
		metric := convertToTelegrafMetric(result, config.Tags, timestamp)

		// Output as JSON (one line per metric)
		output, err := json.Marshal(metric)
		if err != nil {
			log.Printf("Warning: failed to marshal metric: %v", err)
			continue
		}

		fmt.Println(string(output))
		metricsCount++
	}

	if err := cursor.Err(); err != nil {
		return fmt.Errorf("cursor error: %w", err)
	}

	// Log metrics count to stderr (won't interfere with stdout)
	log.Printf("Successfully output %d metrics for query: %s", metricsCount, config.Name)

	return nil
}

// convertToTelegrafMetric converts a MongoDB result document to Telegraf metric format
// Numeric values go to fields, strings go to tags
func convertToTelegrafMetric(result bson.M, baseTags map[string]string, timestamp int64) TelegrafMetric {
	fields := make(map[string]interface{})
	tags := make(map[string]string)

	// Copy base tags from config
	for k, v := range baseTags {
		tags[k] = v
	}

	// Process MongoDB result fields
	for key, value := range result {
		switch v := value.(type) {
		case int, int32, int64:
			fields[key] = v
		case float32, float64:
			fields[key] = v
		case bool:
			fields[key] = v
		case string:
			// Strings become tags
			tags[key] = v
		case bson.M:
			// Handle nested objects (from $group _id, etc.)
			for nestedKey, nestedValue := range v {
				switch nv := nestedValue.(type) {
				case string:
					tags[nestedKey] = nv
				case int, int32, int64:
					fields[nestedKey] = nv
				case float32, float64:
					fields[nestedKey] = nv
				default:
					tags[nestedKey] = fmt.Sprintf("%v", nv)
				}
			}
		default:
			// Convert everything else to string tag
			tags[key] = fmt.Sprintf("%v", v)
		}
	}

	return TelegrafMetric{
		Fields:    fields,
		Tags:      tags,
		Timestamp: timestamp,
	}
}
