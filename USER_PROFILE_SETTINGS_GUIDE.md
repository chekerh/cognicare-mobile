# Guide - Gestion du Profil Utilisateur et Paramètres

## Vue d'ensemble

Ce guide documente le système complet de gestion du profil utilisateur, incluant l'upload sécurisé de photo de profil, le changement de mot de passe et la modification d'email.

## Fonctionnalités

### 1. Upload de Photo de Profil

#### Frontend (Flutter)

**Écran**: `frontend/lib/screens/profile/settings_screen.dart`

**Fonctionnalités**:
- Sélection de photo depuis la galerie
- Prise de photo avec la caméra
- Compression automatique (max 1024x1024, qualité 85%)
- Affichage en temps réel de la photo mise à jour
- Indicateur de chargement pendant l'upload

**Service**: `frontend/lib/services/auth_service.dart`

```dart
Future<String> uploadProfilePicture(String imagePath)
```

**Méthode**:
1. L'utilisateur clique sur l'icône caméra sur la photo de profil
2. Un modal s'affiche avec deux options : Galerie ou Caméra
3. L'image sélectionnée est automatiquement compressée
4. Upload via multipart/form-data
5. Le provider AuthProvider est mis à jour avec la nouvelle URL
6. La photo s'affiche immédiatement dans l'UI

#### Backend (NestJS)

**Endpoint**: `POST /api/v1/auth/upload-profile-picture`

**Controller**: `backend/src/auth/auth.controller.ts`

**Validations**:
- Formats acceptés: JPEG, PNG, WebP
- Taille max: 5MB (configurable)
- Authentification JWT requise

**Stockage**:
- **Cloudinary** (production): Upload sécurisé avec folder `cognicare/profiles`
- **Local Storage** (développement): Sauvegardé dans `uploads/profiles/`

**Service**: `backend/src/auth/auth.service.ts`

```typescript
async uploadProfilePicture(
  userId: string,
  file: { buffer: Buffer; mimetype: string }
)
```

**Processus**:
1. Validation du fichier (type et taille)
2. Upload vers Cloudinary ou local storage
3. Mise à jour du champ `profilePic` dans la base de données
4. Retour du profil utilisateur mis à jour

### 2. Changement de Mot de Passe

#### Frontend

**UI**: Section dédiée dans `settings_screen.dart`

**Champs**:
- Mot de passe actuel (avec validation)
- Nouveau mot de passe (minimum 6 caractères)
- Confirmation du nouveau mot de passe

**Service**:

```dart
Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
})
```

**Validations**:
- Tous les champs requis
- Nouveau mot de passe ≥ 6 caractères
- Confirmation doit correspondre au nouveau mot de passe

#### Backend

**Endpoint**: `PATCH /api/v1/auth/change-password`

**Body**:
```json
{
  "currentPassword": "oldPassword123",
  "newPassword": "newPassword123"
}
```

**Processus**:
1. Vérification de l'authentification (JWT)
2. Validation du mot de passe actuel avec bcrypt
3. Hashing du nouveau mot de passe
4. Mise à jour dans la base de données
5. **Sécurité**: Invalidation de tous les refresh tokens

### 3. Changement d'Email

#### Frontend

**UI**: Section dédiée dans `settings_screen.dart`

**Champs**:
- Nouvel email (avec validation de format)

**Service**:

```dart
Future<void> changeEmail(String newEmail)
```

**Validations**:
- Format email valide (regex)
- Champ requis

**Workflow**:
1. L'utilisateur entre un nouvel email
2. Un email de vérification est envoyé à la nouvelle adresse
3. L'utilisateur doit cliquer sur le lien de vérification
4. L'email est mis à jour après vérification

#### Backend

**Endpoint**: `PATCH /api/v1/auth/change-email`

**Body**:
```json
{
  "newEmail": "newemail@example.com"
}
```

**Processus**:
1. Vérification que l'email n'est pas déjà utilisé
2. Génération d'un code de vérification (6 chiffres)
3. Stockage du code hashé avec expiration (10 minutes)
4. Envoi de l'email de vérification via MailService
5. **Note**: L'email n'est pas mis à jour immédiatement (nécessite vérification)

## Écran de Paramètres

### Navigation

**Route**: `/family/settings`

**Constante**: `AppConstants.familySettingsRoute`

**Accès**: Via le bouton settings (⚙️) en haut à gauche de l'écran ProfileScreen

### Sections

1. **Photo de profil**
   - Affichage de la photo actuelle
   - Bouton caméra pour changer
   - Nom et email de l'utilisateur

2. **Changer le mot de passe**
   - Formulaire avec validation
   - Toggle pour afficher/masquer les mots de passe
   - Bouton de soumission avec indicateur de chargement

3. **Changer l'email**
   - Formulaire avec validation
   - Message de confirmation après envoi

### Design

**Couleurs** (alignées avec le dashboard):
- Primary: `#A3D9E5`
- Primary Dark: `#7BBCCB`
- Background: `#F8FAFC`
- Slate 800: `#1E293B`
- Slate 600: `#475569`
- Slate 500: `#64748B`

**Composants**:
- Cards blanches avec ombres légères
- Boutons arrondis (12px)
- Animations de chargement
- Messages de succès/erreur via SnackBar

## Sécurité

### Upload de Photo

1. **Validation stricte des types de fichiers**
   - Backend rejette tout fichier non-image
   - Mime-type vérifié

2. **Limitation de taille**
   - Max 5MB côté backend
   - Compression côté frontend (1024x1024)

3. **Stockage sécurisé**
   - Cloudinary avec URL sécurisée
   - Nom de fichier unique par utilisateur
   - Pas d'accès direct sans authentification

4. **Écrasement automatique**
   - Un seul fichier par utilisateur (userId comme nom)
   - Ancienne photo automatiquement remplacée

### Changement de Mot de Passe

1. **Vérification de l'ancien mot de passe**
   - Prévient les changements non autorisés

2. **Hashing bcrypt**
   - Tous les mots de passe sont hashés
   - Salt automatique

3. **Invalidation des tokens**
   - Tous les refresh tokens sont supprimés
   - Force la reconnexion sur tous les appareils

### Changement d'Email

1. **Vérification d'unicité**
   - Empêche l'utilisation d'emails déjà enregistrés

2. **Processus de vérification**
   - Code à 6 chiffres hashé
   - Expiration après 10 minutes
   - Doit être vérifié avant application

## Configuration Backend

### Variables d'environnement

```env
# Cloudinary (recommandé pour production)
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Email Service
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=noreply@cognicare.com
```

### Modules requis

```typescript
// app.module.ts
@Module({
  imports: [
    ConfigModule.forRoot(),
    MulterModule.register({
      limits: {
        fileSize: 5 * 1024 * 1024, // 5MB
      },
    }),
    // ... autres modules
  ],
})
```

## Installation et Setup

### Frontend

1. **Dépendances déjà installées**:
   ```yaml
   # pubspec.yaml
   image_picker: ^1.0.7
   http: ^1.2.0
   http_parser: ^4.0.2
   provider: ^6.1.1
   ```

2. **Configuration iOS** (Info.plist):
   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>Nous avons besoin d'accéder à vos photos pour mettre à jour votre photo de profil.</string>
   <key>NSCameraUsageDescription</key>
   <string>Nous avons besoin d'accéder à votre caméra pour prendre une photo de profil.</string>
   ```

3. **Configuration Android** (AndroidManifest.xml):
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   ```

### Backend

1. **Installer les dépendances**:
   ```bash
   npm install @nestjs/platform-express multer cloudinary
   ```

2. **Créer le dossier uploads** (si local storage):
   ```bash
   mkdir -p uploads/profiles
   ```

3. **Configurer Cloudinary** (recommandé):
   - Créer un compte sur cloudinary.com
   - Obtenir les credentials
   - Ajouter au fichier `.env`

## Tests

### Frontend

1. **Test upload de photo**:
   - Ouvrir ProfileScreen
   - Cliquer sur l'icône settings (⚙️)
   - Cliquer sur l'icône caméra sur la photo
   - Sélectionner "Galerie" ou "Caméra"
   - Vérifier que la photo s'affiche immédiatement

2. **Test changement de mot de passe**:
   - Dans Settings, remplir le formulaire de mot de passe
   - Soumettre avec un mot de passe incorrect → Erreur
   - Soumettre avec un mot de passe correct → Succès
   - Se déconnecter et reconnecter avec le nouveau mot de passe

3. **Test changement d'email**:
   - Entrer un nouvel email
   - Vérifier la réception de l'email de vérification
   - Cliquer sur le lien de vérification

### Backend

1. **Test endpoint upload**:
   ```bash
   curl -X POST \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -F "file=@path/to/image.jpg" \
     http://localhost:3000/api/v1/auth/upload-profile-picture
   ```

2. **Test changement de mot de passe**:
   ```bash
   curl -X PATCH \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"currentPassword":"old123","newPassword":"new123"}' \
     http://localhost:3000/api/v1/auth/change-password
   ```

3. **Test changement d'email**:
   ```bash
   curl -X PATCH \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"newEmail":"newemail@example.com"}' \
     http://localhost:3000/api/v1/auth/change-email
   ```

## Dépannage

### Problèmes courants

1. **"No file provided"**
   - Vérifier que le champ form-data s'appelle bien `file`
   - Vérifier les permissions de l'appareil

2. **"Email already in use"**
   - L'email existe déjà dans la base de données
   - Utiliser un email différent

3. **"Current password is incorrect"**
   - Vérifier le mot de passe actuel
   - Réinitialiser via "Forgot Password" si nécessaire

4. **Upload échoue sur iOS**
   - Vérifier les permissions dans Info.plist
   - Redémarrer l'app après ajout des permissions

5. **Image ne s'affiche pas**
   - Vérifier le chemin de l'image retourné par le backend
   - Vérifier la configuration Cloudinary
   - En local, vérifier que le dossier `uploads/profiles` existe

## Améliorations futures

1. **Upload de photo**:
   - Cropping d'image avant upload
   - Support de plusieurs formats (GIF, SVG)
   - Aperçu avant upload

2. **Changement d'email**:
   - Endpoint pour compléter le changement après vérification
   - Possibilité d'annuler le changement

3. **Sécurité**:
   - Authentification à deux facteurs (2FA)
   - Historique des changements de mot de passe
   - Notification par email lors des changements

4. **UI/UX**:
   - Animation lors de l'upload
   - Prévisualisation du crop avant upload
   - Mode sombre pour l'écran settings

## API Documentation

Tous les endpoints sont documentés dans Swagger :

**URL**: `http://localhost:3000/api`

**Endpoints**:
- `POST /api/v1/auth/upload-profile-picture` - Upload photo de profil
- `PATCH /api/v1/auth/change-password` - Changer mot de passe
- `PATCH /api/v1/auth/change-email` - Changer email

## Conclusion

Ce système de gestion de profil offre une expérience utilisateur fluide et sécurisée pour la gestion des informations personnelles. Toutes les opérations sensibles sont protégées par authentification JWT et validation stricte des données.
