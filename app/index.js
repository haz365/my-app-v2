// ─── Entry point ─────────────────────────────────────────────
// This file starts the server
// Kept separate from server.js so tests can import
// the app without binding to a real port

const app = require('./server');

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Region: ${process.env.AWS_REGION || 'eu-west-2'}`);
  console.log(`DynamoDB table: ${process.env.DYNAMO_TABLE || 'visit-counter'}`);
});