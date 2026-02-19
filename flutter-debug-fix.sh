#!/bin/bash

# Script pour lancer Flutter avec débogage sur iOS
# Utilise une connexion USB directe

cd /Users/malekbenslimen/Desktop/CogniCare/frontend

echo "🔧 Nettoyage des processus existants..."
pkill -f "flutter run" 2>/dev/null

echo "🧹 Nettoyage du build Flutter..."
flutter clean

echo "📦 Récupération des dépendances..."
flutter pub get

echo "🍎 Installation des pods..."
cd ios && pod install && cd ..

echo "🚀 Lancement de l'app en mode debug..."
flutter run -d "00008150-00061D84347A401C" --disable-service-auth-codes

echo "✅ Terminé!"
