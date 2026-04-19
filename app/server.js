// ─── Imports ─────────────────────────────────────────────────
const express = require('express');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const os = require('os');

// ─── App setup ───────────────────────────────────────────────
const app = express();

// Read config from environment variables
// These are injected by ECS at runtime (defined in the task definition)
const PORT        = process.env.PORT        || 3000;
const AWS_REGION  = process.env.AWS_REGION  || 'eu-west-2';
const TABLE_NAME  = process.env.DYNAMO_TABLE || 'visit-counter';

// ─── AWS SDK setup ───────────────────────────────────────────
// DynamoDBClient connects to AWS DynamoDB
// Credentials are automatically picked up from the ECS Task Role
// We NEVER hardcode credentials — IAM role handles it
const client    = new DynamoDBClient({ region: AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// ─── Routes ──────────────────────────────────────────────────

// /health — ALB hits this every 30 seconds
// Must return 200 or ALB marks the container as unhealthy
// Deliberately has NO DynamoDB dependency
// (if DynamoDB has issues we don't want ALB to kill our containers)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// / — main endpoint, increments and returns the visit counter
app.get('/', async (req, res) => {
  try {
    // Atomically increment the visits counter in DynamoDB
    // ADD is atomic — safe even with thousands of simultaneous requests
    const result = await docClient.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { id: 'homepage' },
      UpdateExpression: 'ADD visits :inc',
      ExpressionAttributeValues: { ':inc': 1 },
      ReturnValues: 'UPDATED_NEW',
    }));

    res.json({
      message:     'Hello from my-app-v2 on AWS Fargate!',
      visit_count: result.Attributes.visits,
      hostname:    os.hostname(),        // shows which container served this
      timestamp:   new Date().toISOString(),
    });

  } catch (err) {
    // Log full error server-side (visible in CloudWatch)
    console.error('DynamoDB error:', err);

    // Return generic error to the client (don't leak internals)
    res.status(500).json({ error: 'Something went wrong' });
  }
});

// ─── Start server ─────────────────────────────────────────────
// 0.0.0.0 = listen on ALL network interfaces
// (not just localhost — required for Docker + ECS to route traffic in)
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Region: ${AWS_REGION}`);
  console.log(`DynamoDB table: ${TABLE_NAME}`);
});