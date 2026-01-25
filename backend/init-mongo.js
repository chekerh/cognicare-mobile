// MongoDB initialization script
// This runs when the MongoDB container starts for the first time

db = db.getSiblingDB('cognicare');

// Create indexes for better performance
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "role": 1 });
db.users.createIndex({ "createdAt": 1 });

// Optional: Create a sample admin user (remove in production)
// Uncomment the following lines if you want a default admin user

/*
db.users.insertOne({
  fullName: "Admin User",
  email: "admin@cognicare.com",
  passwordHash: "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewfLkIwF5qcO7G6", // password: admin123
  role: "doctor",
  createdAt: new Date()
});
*/

print('Database initialization completed.');