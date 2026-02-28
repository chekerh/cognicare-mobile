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

// Default certification test for volunteers (MCQ)
db.certificationtests.updateOne(
  { slug: "default" },
  { $setOnInsert: {
    slug: "default",
    title: "Test de certification bénévole",
    passingScorePercent: 80,
    questions: [
      { type: "mcq", text: "Quelle attitude privilégier avec un enfant autiste en crise ?", options: ["Le contraindre physiquement", "Rester calme et proposer un espace apaisant", "Élever la voix pour se faire entendre", "Le laisser seul sans surveillance"], correctOptionIndex: 1 },
      { type: "mcq", text: "La communication non verbale (gestes, pictogrammes) est-elle utile ?", options: ["Rarement", "Oui, elle peut réduire l'anxiété et faciliter la compréhension", "Seulement pour les tout-petits", "Non, il faut toujours parler"], correctOptionIndex: 1 },
      { type: "mcq", text: "En tant que bénévole CogniCare, que faire si un parent vous demande un avis médical ?", options: ["Donner votre avis personnel", "Orienter vers un professionnel de santé et ne pas remplacer le médecin", "Refuser de répondre", "Recommander des médicaments"], correctOptionIndex: 1 },
      { type: "mcq", text: "À quoi sert le cadre d'intervention défini avec la famille ?", options: ["À limiter vos horaires uniquement", "À clarifier les rôles, les limites et les objectifs pour la sécurité de tous", "À remplacer le médecin", "À imposer des règles à l'enfant"], correctOptionIndex: 1 },
      { type: "mcq", text: "Que faire si vous constatez une situation qui vous inquiète concernant l'enfant ?", options: ["En parler uniquement à l'enfant", "Signaler à la structure CogniCare / responsable et aux parents selon le cadre", "Ne rien dire pour ne pas inquiéter", "Publier sur les réseaux sociaux"], correctOptionIndex: 1 }
    ],
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