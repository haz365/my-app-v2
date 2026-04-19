// ─── Imports ─────────────────────────────────────────────────
const express = require('express');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const os = require('os');

// ─── App setup ───────────────────────────────────────────────
const app = express();

const PORT       = process.env.PORT        || 3000;
const AWS_REGION = process.env.AWS_REGION  || 'eu-west-2';
const TABLE_NAME = process.env.DYNAMO_TABLE || 'visit-counter';

// ─── AWS SDK ─────────────────────────────────────────────────
const client    = new DynamoDBClient({ region: AWS_REGION });
const docClient = DynamoDBDocumentClient.from(client);

// ─── Helper: generate the HTML page ──────────────────────────
// Takes the visit count and returns a full HTML string
const generateHTML = (visitCount, error = null) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My App V2</title>
  <style>
    /* ── Reset ───────────────────────────────────────────── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    /* ── Base ────────────────────────────────────────────── */
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0f0f1a;
      color: #ffffff;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }

    /* ── Card ────────────────────────────────────────────── */
    .card {
      background: #1a1a2e;
      border: 1px solid #2a2a4a;
      border-radius: 24px;
      padding: 60px 48px;
      max-width: 600px;
      width: 100%;
      text-align: center;
      box-shadow: 0 25px 60px rgba(0,0,0,0.5);
    }

    /* ── Logo ────────────────────────────────────────────── */
    .logo {
      width: 80px;
      height: 80px;
      background: linear-gradient(135deg, #667eea, #764ba2);
      border-radius: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 32px;
      font-size: 36px;
    }

    /* ── Heading ─────────────────────────────────────────── */
    h1 {
      font-size: 2rem;
      font-weight: 700;
      margin-bottom: 12px;
      background: linear-gradient(135deg, #667eea, #a78bfa);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }

    .subtitle {
      color: #8888aa;
      font-size: 1rem;
      margin-bottom: 48px;
      line-height: 1.6;
    }

    /* ── Counter ─────────────────────────────────────────── */
    .counter-section {
      background: #0f0f1a;
      border: 1px solid #2a2a4a;
      border-radius: 16px;
      padding: 32px;
      margin-bottom: 32px;
    }

    .counter-label {
      font-size: 0.85rem;
      text-transform: uppercase;
      letter-spacing: 2px;
      color: #8888aa;
      margin-bottom: 12px;
    }

    .counter-number {
      font-size: 4rem;
      font-weight: 800;
      background: linear-gradient(135deg, #667eea, #a78bfa);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      line-height: 1;
      margin-bottom: 8px;
    }

    .counter-sublabel {
      font-size: 0.85rem;
      color: #8888aa;
    }

    /* ── Stats grid ──────────────────────────────────────── */
    .stats {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 32px;
    }

    .stat {
      background: #0f0f1a;
      border: 1px solid #2a2a4a;
      border-radius: 12px;
      padding: 20px;
      text-align: left;
    }

    .stat-label {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: #8888aa;
      margin-bottom: 6px;
    }

    .stat-value {
      font-size: 0.9rem;
      color: #ffffff;
      font-weight: 500;
      word-break: break-all;
    }

    /* ── Badge ───────────────────────────────────────────── */
    .badges {
      display: flex;
      gap: 8px;
      justify-content: center;
      flex-wrap: wrap;
    }

    .badge {
      background: #2a2a4a;
      border: 1px solid #3a3a5a;
      border-radius: 20px;
      padding: 6px 14px;
      font-size: 0.8rem;
      color: #a78bfa;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .badge-dot {
      width: 6px;
      height: 6px;
      background: #22c55e;
      border-radius: 50%;
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.4; }
    }

    /* ── Error state ─────────────────────────────────────── */
    .error {
      background: #2a1a1a;
      border: 1px solid #4a2a2a;
      border-radius: 12px;
      padding: 20px;
      color: #ff8888;
      font-size: 0.9rem;
      margin-bottom: 24px;
    }

    /* ── Refresh button ──────────────────────────────────── */
    .refresh-btn {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: linear-gradient(135deg, #667eea, #764ba2);
      color: white;
      border: none;
      border-radius: 12px;
      padding: 14px 28px;
      font-size: 0.95rem;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      transition: opacity 0.2s;
      margin-top: 8px;
    }

    .refresh-btn:hover { opacity: 0.85; }
  </style>
</head>
<body>
  <div class="card">

    <!-- Logo -->
    <div class="logo">🚀</div>

    <!-- Heading -->
    <h1>My App V2</h1>
    <p class="subtitle">
      A Node.js app running on AWS ECS Fargate,<br>
      deployed with Terraform and GitHub Actions.
    </p>

    <!-- Error state -->
    ${error ? `
    <div class="error">
      ⚠️ Could not connect to DynamoDB: ${error}
    </div>
    ` : ''}

    <!-- Visit counter -->
    <div class="counter-section">
      <div class="counter-label">Total visits</div>
      <div class="counter-number">${visitCount ?? '—'}</div>
      <div class="counter-sublabel">
        ${visitCount ? 'Powered by DynamoDB' : 'DynamoDB not available'}
      </div>
    </div>

    <!-- Stats -->
    <div class="stats">
      <div class="stat">
        <div class="stat-label">Region</div>
        <div class="stat-value">${AWS_REGION}</div>
      </div>
      <div class="stat">
        <div class="stat-label">Container</div>
        <div class="stat-value">${os.hostname()}</div>
      </div>
      <div class="stat">
        <div class="stat-label">Time</div>
        <div class="stat-value">${new Date().toUTCString()}</div>
      </div>
      <div class="stat">
        <div class="stat-label">Table</div>
        <div class="stat-value">${TABLE_NAME}</div>
      </div>
    </div>

    <!-- Badges -->
    <div class="badges">
      <span class="badge">
        <span class="badge-dot"></span>
        ECS Fargate
      </span>
      <span class="badge">
        <span class="badge-dot"></span>
        DynamoDB
      </span>
      <span class="badge">
        <span class="badge-dot"></span>
        Terraform
      </span>
      <span class="badge">
        <span class="badge-dot"></span>
        GitHub Actions
      </span>
    </div>

    <!-- Refresh -->
    <br>
    <a href="/" class="refresh-btn">
      🔄 Refresh (increments counter)
    </a>

  </div>
</body>
</html>
`;

// ─── Routes ──────────────────────────────────────────────────

// /health — ALB health check (still returns JSON)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// / — main page, increments counter, returns HTML
app.get('/', async (req, res) => {
  try {
    const result = await docClient.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { id: 'homepage' },
      UpdateExpression: 'ADD visits :inc',
      ExpressionAttributeValues: { ':inc': 1 },
      ReturnValues: 'UPDATED_NEW',
    }));

    const visits = result.Attributes.visits;

    // Return HTML instead of JSON
    res.setHeader('Content-Type', 'text/html');
    res.send(generateHTML(visits));

  } catch (err) {
    console.error('DynamoDB error:', err);

    // Even on error, return a nice HTML page
    res.status(500).setHeader('Content-Type', 'text/html');
    res.send(generateHTML(null, err.message));
  }
});

// ─── Export ───────────────────────────────────────────────────
module.exports = app;