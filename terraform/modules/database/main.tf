# ═══════════════════════════════════════════════════════════════
# DATABASE MODULE
# Creates the DynamoDB table our app uses for the visit counter
#
# NOTE: this is completely separate from the "terraform-locks"
# table we created manually for Terraform state locking.
# That table is used BY Terraform itself.
# This table is used BY our Node.js application.
# ═══════════════════════════════════════════════════════════════

resource "aws_dynamodb_table" "visit_counter" {
  name = "visit-counter"

  # PAY_PER_REQUEST = serverless billing
  # Pay per read/write operation — no capacity planning needed
  # Perfect for unpredictable or low traffic workloads
  billing_mode = "PAY_PER_REQUEST"

  # Primary key — must match what server.js uses:
  # Key: { id: 'homepage' }
  hash_key = "id"

  # Only KEY attributes need to be declared upfront in DynamoDB
  # Other fields (like "visits") are added dynamically by the app
  # This is the NoSQL flexibility advantage over relational DBs
  attribute {
    name = "id"
    type = "S"   # S = String
  }

  tags = {
    Name = "${var.project_name}-visit-counter"
  }
}