# Système de Routine Quotidienne et Rappels - CogniCare

## 📋 Vue d'ensemble

Ce système permet aux parents de créer et gérer des rappels basés sur des tâches pour leurs enfants (boire de l'eau, prendre des médicaments, faire les devoirs, etc.). Les rappels sont intégrés avec le plan nutritionnel de l'enfant.

## ✨ Nouveautés (Dernière mise à jour)

### 🎯 Système de Templates
- **8 tâches pré-configurées** prêtes à l'emploi
- **Création instantanée** en un clic
- **Interface moderne** avec grille colorée
- **Personnalisation** : chaque tâche a son icône, couleur et horaire

### 🚀 Expérience Utilisateur Optimisée
- **Bouton FAB** : Accès rapide à la création depuis la routine
- **État vide intelligent** : Guide l'utilisateur vers la création
- **Rafraîchissement automatique** : Liste mise à jour après chaque ajout
- **Messages de confirmation** : Feedback visuel à chaque action

### 💊 Vérification par Photo pour Médicaments ⭐ NOUVEAU
- **Preuve obligatoire** : Pour les tâches de type "Médicament", une photo est requise
- **Capture automatique** : Ouverture de la caméra pour prendre un selfie
- **Instructions claires** : Guide l'enfant étape par étape
- **Stockage sécurisé** : Les photos sont sauvegardées côté serveur
- **Interface animée** : Animations et feedback visuels encourageants
- **Validation instantanée** : Confirmation visuelle une fois la photo prise

## 🎯 Fonctionnalités

### Frontend (Flutter)

#### Écrans créés :
1. **Child Daily Routine Screen** (`child_daily_routine_screen.dart`)
   - Affiche toutes les tâches du jour de l'enfant
   - Permet de cocher/décocher les tâches complétées
   - Barre de progression visuelle
   - Design adapté aux enfants avec de grandes icônes et couleurs
   - **Bouton FAB "Ajouter une tâche"** pour créer rapidement de nouveaux rappels
   - État vide avec bouton d'action pour ajouter des tâches

2. **Create Reminder Screen** (`create_reminder_screen.dart`) ⭐ NOUVEAU
   - Interface de création de rappels avec **templates pré-configurés**
   - 8 tâches courantes disponibles en un clic :
     - 🪥 Brush Teeth (Se brosser les dents)
     - 💊 Take Medicine (Prendre les médicaments)
     - 😊 Wash Face (Se laver le visage)
     - 👕 Get Dressed (S'habiller)
     - 🍴 Eat Breakfast (Prendre le petit-déjeuner)
     - 💧 Drink Water (Boire de l'eau)
     - 🎒 Pack Bag (Préparer le sac)
     - 📚 Do Homework (Faire les devoirs)
   - Chaque template inclut : icône, titre, description, heure/fréquence, couleur
   - Design en grille moderne et coloré
   - Création instantanée en un clic

3. **Reminder Notification Screen** (`reminder_notification_screen.dart`)
   - Notification visuelle animée pour chaque rappel
   - Grande icône animée avec un smiley
   - Badge Raspberry Pi connecté
   - Cercle de temps animé

4. **Carte Dashboard** (dans `family_member_dashboard_screen.dart`)
   - Nouvelle carte "Routine & Rappels" dans le dashboard famille
   - Navigation automatique vers la routine quotidienne

#### Models :
- **TaskReminder** : Modèle pour les rappels de tâches
  - Types : water, meal, medication, homework, activity, hygiene, custom
  - Fréquences : once, daily, weekly, interval
  - Paramètres : son, vibration, sync Raspberry Pi

- **NutritionPlan** : Modèle pour les plans nutritionnels
  - Objectifs d'hydratation
  - Horaires des repas
  - Médicaments et suppléments
  - Allergies et restrictions

#### Services :
- **RemindersService** : Communication avec l'API des rappels
  - `getTodayReminders(childId)` : Récupère les rappels du jour
  - `completeTask(reminderId, completed, date)` : Marque une tâche comme complétée

- **NutritionService** : Communication avec l'API nutrition
  - `getNutritionPlansByChild(childId)` : Récupère les plans nutritionnels
  - `createNutritionPlan(planData)` : Crée un nouveau plan
  - `updateNutritionPlan(planId, planData)` : Met à jour un plan

### Backend (NestJS)

#### Module Nutrition (`backend/src/nutrition/`)

Déjà complètement implémenté avec :

**Contrôleurs :**
- `NutritionController` : CRUD pour les plans nutritionnels
- `RemindersController` : CRUD pour les rappels

**Services :**
- `NutritionService` : Logique métier pour les plans nutritionnels
- `RemindersService` : Logique métier pour les rappels

**Endpoints principaux :**
```
POST   /api/v1/reminders                      - Créer un rappel
GET    /api/v1/reminders/child/:childId       - Tous les rappels d'un enfant
GET    /api/v1/reminders/child/:childId/today - Rappels du jour
PATCH  /api/v1/reminders/:reminderId          - Modifier un rappel
POST   /api/v1/reminders/complete             - Marquer une tâche comme complétée
DELETE /api/v1/reminders/:reminderId          - Désactiver un rappel
GET    /api/v1/reminders/child/:childId/stats - Statistiques de complétion

POST   /api/v1/nutrition/plans                      - Créer un plan nutritionnel
GET    /api/v1/nutrition/plans/child/:childId       - Plans d'un enfant
PATCH  /api/v1/nutrition/plans/:planId              - Modifier un plan
```

## 🔄 Flux de données

1. **Affichage de la routine quotidienne :**
   ```
   Dashboard → Carte "Routine & Rappels" → Child Daily Routine Screen
   → RemindersService.getTodayReminders(childId)
   → Backend /api/v1/reminders/child/:childId/today
   → Affichage des tâches avec état de complétion
   ```

2. **Complétion d'une tâche :**
   ```
   User clique sur checkbox → RemindersService.completeTask()
   → Backend /api/v1/reminders/complete
   → Mise à jour de l'UI + Message de félicitation
   ```

3. **Navigation vers notification :**
   ```
   User clique sur une tâche → Navigation avec extras
   → Reminder Notification Screen avec animation
   ```

## 🎨 Design

Le design suit les mockups fournis avec :
- Fond bleu ciel (#BFE3F5)
- Cartes blanches avec ombres légères
- Grandes icônes emoji pour chaque type de tâche
- Animations fluides (scale, rotation)
- Barre de progression visuelle
- État vide avec message encourageant

## 🔐 Sécurité

- Toutes les routes sont protégées par JWT (`JwtAuthGuard`)
- Vérification des permissions (rôle `family` requis)
- Validation des relations parent-enfant dans le backend

## 🚀 Utilisation

### Comment ajouter des tâches pour votre enfant :

**Méthode 1 : Via l'état vide (première fois)**
1. Allez dans le Dashboard Famille
2. Cliquez sur la carte **"Routine & Rappels"**
3. Dans l'écran vide, cliquez sur **"Ajouter des tâches"**
4. Sélectionnez une ou plusieurs tâches parmi les templates
5. Les tâches apparaîtront immédiatement dans la routine quotidienne

**Méthode 2 : Via le bouton FAB (après avoir des tâches)**
1. Dans l'écran "Child Daily Visual Routine"
2. Cliquez sur le bouton **"+ Ajouter une tâche"** en bas à droite
3. Sélectionnez les nouvelles tâches à ajouter
4. La liste se rafraîchit automatiquement

**Méthode 3 : Par programmation (pour développeurs)**

```dart
final reminderData = {
  'childId': childId,
  'type': 'water',
  'title': 'Boire de l\'eau',
  'description': 'N\'oublie pas de boire un grand verre d\'eau',
  'frequency': 'interval',
  'intervalMinutes': 120,
  'soundEnabled': true,
  'vibrationEnabled': true,
  'piSyncEnabled': false,
};

await RemindersService(
  getToken: () => AuthService().getStoredToken(),
).createReminder(reminderData);
```

### Templates disponibles :

| Icône | Tâche | Fréquence | Horaire | Type |
|-------|-------|-----------|---------|------|
| 🪥 | Brush Teeth | Quotidien | 08:00 | Hygiène |
| 💊 | Take Medicine | Quotidien | 09:00 | Médicament |
| 😊 | Wash Face | Quotidien | 08:30 | Hygiène |
| 👕 | Get Dressed | Quotidien | 08:45 | Activité |
| 🍴 | Eat Breakfast | Quotidien | 09:00 | Repas |
| 💧 | Drink Water | Intervalle | 120min | Eau |
| 🎒 | Pack Bag | Quotidien | 10:00 | Activité |
| 📚 | Do Homework | Quotidien | 16:00 | Devoirs |

## 📱 Intégration Raspberry Pi

Le système est prêt pour l'intégration avec Raspberry Pi :
- Badge "PI CONNECTÉ" dans l'interface
- Flag `piSyncEnabled` dans les rappels
- Peut envoyer des notifications physiques via le Pi

## 💊 Système de Vérification par Photo (Médicaments)

### Comment ça marche ?

Quand un enfant essaie de cocher une tâche de type **"Take Medicine"**, au lieu de simplement la marquer comme complétée, le système :

1. **Détecte automatiquement** que c'est une tâche médicament
2. **Ouvre l'écran de vérification** avec instructions claires
3. **Active la caméra frontale** pour un selfie
4. **Guide l'enfant** avec 3 étapes illustrées :
   - 📦 Préparer les médicaments
   - 💧 Les prendre avec de l'eau
   - 📸 Prendre une photo (selfie)
5. **Permet de reprendre** la photo si nécessaire
6. **Envoie la preuve** au serveur avec validation
7. **Affiche une confirmation** avec message encourageant

### Architecture Technique

#### Frontend (Flutter)
```
child_daily_routine_screen.dart
  ↓ Clic sur checkbox médicament
_toggleTaskCompletion() détecte ReminderType.medication
  ↓ Navigation vers
MedicineVerificationScreen
  ↓ Utilise ImagePicker
Capture photo (source: camera, frontale)
  ↓ Preview + validation
RemindersService.completeTaskWithProof()
  ↓ Upload multipart/form-data
Backend reçoit image + données
```

#### Backend (NestJS)
```
POST /api/v1/reminders/complete
  ↓ @UseInterceptors(FileInterceptor('proofImage'))
RemindersController.completeTask()
  ↓ Reçoit DTO + fichier optionnel
RemindersService.completeTask()
  ↓ Sauvegarde dans /uploads/proof-images/
Mise à jour TaskReminder.completionHistory
  ↓ Ajout proofImageUrl
Retour avec succès
```

### Structure de Stockage

**Fichiers :**
```
backend/uploads/proof-images/
  ├── 679f6619aac148861803c_1739482520000_proof.jpg
  ├── 679f6619aac148861803c_1739482680000_proof.jpg
  └── ...
```

**Base de données (MongoDB) :**
```json
{
  "completionHistory": [
    {
      "date": "2026-02-13T00:00:00.000Z",
      "completed": true,
      "completedAt": "2026-02-13T14:30:00.000Z",
      "proofImageUrl": "/uploads/proof-images/679f6619aac148861803c_1739482520000_proof.jpg"
    }
  ]
}
```

### Sécurité

1. **Authentification JWT** : Requise pour upload
2. **Validation des permissions** : Vérification parent-enfant
3. **Type MIME** : Validation des formats image
4. **Noms de fichiers uniques** : `{reminderId}_{timestamp}_{original}`
5. **Stockage isolé** : Dossier dédié aux preuves

### Configuration Requise

**Frontend :**
- Package `image_picker: ^1.0.7` (✅ ajouté dans `pubspec.yaml`)
- Permissions caméra dans `Info.plist` (iOS) et `AndroidManifest.xml` (Android)
- **📖 Voir le guide complet** : `CAMERA_PERMISSIONS_SETUP.md`

**Backend :**
- Multer (déjà inclus avec NestJS)
- Dossier `uploads/proof-images/` créé automatiquement
- Aucune configuration supplémentaire requise

**Installation :**
```bash
cd frontend
flutter pub get
```

**Pour tester :**
- Utilisez un **appareil réel** (simulateur/émulateur ont des limitations caméra)
- Consultez `CAMERA_PERMISSIONS_SETUP.md` pour la configuration complète

## 📊 Flux Utilisateur Complet

### 1️⃣ Premier lancement (aucune tâche)
```
Dashboard Famille
  ↓ Clic sur "Routine & Rappels"
Child Daily Visual Routine (État vide)
  ↓ Clic sur "Ajouter des tâches"
Create Reminder Screen
  ↓ Sélection d'une tâche (ex: 🪥 Brush Teeth)
Création instantanée + Retour automatique
  ↓
Child Daily Visual Routine (avec la nouvelle tâche)
```

### 2️⃣ Ajout de tâches supplémentaires
```
Child Daily Visual Routine
  ↓ Clic sur FAB "+ Ajouter une tâche"
Create Reminder Screen
  ↓ Sélection de plusieurs tâches
Création + Retour
  ↓
Liste mise à jour automatiquement
```

### 3️⃣ Complétion d'une tâche
```
Child Daily Visual Routine
  ↓ Clic sur checkbox d'une tâche
Appel API pour marquer comme complétée
  ↓
✅ Message de félicitation + Mise à jour UI
  ↓
Barre de progression mise à jour (ex: 3/7)
```

### 4️⃣ Voir les détails d'une tâche
```
Child Daily Visual Routine
  ↓ Clic sur une carte de tâche
Reminder Notification Screen
  ↓ Affichage animé avec détails
Grande icône + Description + Temps
  ↓ Badge "PI CONNECTÉ" si activé
Animations (rotation, scale, pulsation)
```

### 5️⃣ Compléter une tâche "Médicament" (avec vérification) 💊📸
```
Child Daily Visual Routine
  ↓ Clic sur checkbox de "Take Medicine"
Détection automatique → Type = medication
  ↓ Navigation vers
Medicine Verification Screen
  ↓ Instructions affichées
Étape 1: Préparer médicaments
Étape 2: Les prendre avec eau
Étape 3: Prendre photo (selfie)
  ↓ Clic sur "Prendre une photo"
Caméra frontale s'ouvre
  ↓ Capture photo
Preview avec option "Reprendre"
  ↓ Clic sur "Valider la prise"
Upload multipart avec proofImage
  ↓ Backend sauvegarde image
Mise à jour completionHistory avec proofImageUrl
  ↓ Retour automatique
✅ "Médicament vérifié ! Bravo !"
  ↓ Liste rafraîchie
Tâche cochée + barre de progression mise à jour
```

## 🔮 Prochaines étapes suggérées

1. ✅ **Écran de création de rappels** - ✅ TERMINÉ
2. **Formulaire personnalisé** : Permettre de créer des tâches personnalisées (titre, heure, fréquence custom)
3. **Statistiques** : Graphiques de complétion des tâches sur 7/30 jours
4. **Notifications push** : Intégration avec Firebase pour rappels en temps réel
5. **Synchronisation Pi** : Protocole MQTT pour les rappels physiques
6. **Gamification** : Récompenses et badges pour tâches complétées
7. **Édition de rappels** : Modifier/supprimer les rappels existants
8. **Historique** : Voir les statistiques de complétion passées
9. **Plans nutritionnels** : Créer/éditer des plans nutritionnels liés aux rappels
10. **Mode nuit** : Support du thème sombre
