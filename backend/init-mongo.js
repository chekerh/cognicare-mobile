// MongoDB initialization script
// This runs when the MongoDB container starts for the first time

db = db.getSiblingDB('cognicare');

// Create indexes for better performance
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "role": 1 });
db.users.createIndex({ "createdAt": 1 });

// Default qualification course for denied volunteers (upsert to avoid duplicate)
db.courses.updateOne(
  { slug: "formation-qualifiante-benevole" },
  { $setOnInsert: {
    title: "Formation qualifiante bénévole",
    description: "Parcours pour devenir bénévole CogniCare : sensibilisation, bonnes pratiques, cadre d'intervention.",
    slug: "formation-qualifiante-benevole",
    isQualificationCourse: true,
    createdAt: new Date(),
    updatedAt: new Date()
  }},
  { upsert: true }
);

// Optional: Create a default admin user for development
// ⚠️ SECURITY: Admin accounts cannot be created through the signup API
// They must be created manually in the database for security
// Uncomment and customize the following for development only, remove in production

/*
db.users.insertOne({
  fullName: "Admin User",
  email: "admin@cognicare.com",
  passwordHash: "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewfLkIwF5qcO7G6", // password: admin123
  role: "admin",
  createdAt: new Date(),
  updatedAt: new Date()
});
*/

print('Database initialization completed.');