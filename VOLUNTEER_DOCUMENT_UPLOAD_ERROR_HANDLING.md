# Gestion des Erreurs d'Upload de Documents - Section Volontaire

## Vue d'ensemble

Ce guide documente le système amélioré de gestion des erreurs pour l'upload de documents des volontaires. Le système fournit des messages d'erreur clairs et détaillés avec des suggestions de solutions pour aider les utilisateurs à résoudre les problèmes d'upload.

## Problèmes traités

### 1. Fichier trop volumineux (> 5 Mo)

**Détection** :
- Frontend : Vérification de la taille avant l'upload
- Backend : Validation de la taille du buffer

**Message d'erreur** :
```
Fichier trop volumineux
La taille du fichier (X.XX Mo) dépasse la limite de 5 Mo.
```

**Suggestions affichées** :
- Compressez votre image en ligne (ex: tinypng.com, compressjpeg.com)
- Réduisez la résolution de l'image avant de l'uploader
- Pour les PDF : utilisez un compresseur PDF en ligne
- Prenez une nouvelle photo avec une qualité réduite

### 2. Type de fichier invalide

**Formats acceptés** :
- Images : JPG, JPEG, PNG, WebP
- Documents : PDF

**Détection** :
- Frontend : Vérification de l'extension du fichier
- Backend : Validation du MIME type

**Message d'erreur** :
```
Type de fichier invalide
Le format .xxx n'est pas accepté.
```

**Suggestions affichées** :
- Formats acceptés : JPG, JPEG, PNG, WebP, PDF
- Convertissez votre fichier en un format accepté
- Pour les documents : utilisez un scanner d'application pour créer un PDF

### 3. Fichier non accessible

**Causes possibles** :
- Permissions insuffisantes
- Fichier sur un stockage externe non monté
- Problème de système de fichiers

**Message d'erreur** :
```
Fichier non accessible
Le fichier sélectionné n'est pas accessible sur cet appareil.
```

**Suggestions affichées** :
- Vérifiez les permissions de l'application
- Essayez de copier le fichier dans un autre dossier
- Redémarrez l'application et réessayez

### 4. Fichier introuvable

**Causes possibles** :
- Fichier supprimé après sélection
- Fichier déplacé
- Problème de synchronisation cloud

**Message d'erreur** :
```
Fichier introuvable
Le fichier n'existe plus ou a été déplacé.
```

**Suggestions affichées** :
- Vérifiez que le fichier existe toujours
- Sélectionnez un autre fichier

### 5. Erreur de connexion réseau

**Détection** :
- Erreurs contenant "network", "connexion", etc.

**Message d'erreur** :
```
Erreur de connexion
Impossible de se connecter au serveur.
```

**Suggestions affichées** :
- Vérifiez votre connexion internet
- Réessayez dans quelques instants
- Contactez le support si le problème persiste

## Architecture technique

### Frontend (Flutter)

**Fichier** : `frontend/lib/screens/volunteer/volunteer_application_screen.dart`

#### Méthode principale : `_pickAndUpload(String type)`

**Validations effectuées** :
1. Vérification de l'accessibilité du fichier
2. Vérification de l'existence du fichier
3. Vérification de l'extension du fichier
4. Vérification de la taille du fichier

**Flux de traitement** :

```dart
_pickAndUpload(type)
  ↓
FilePicker.pickFiles()
  ↓
Validation de l'accessibilité
  ↓
Validation de l'existence
  ↓
Validation de l'extension
  ↓
Validation de la taille
  ↓
Upload via VolunteerService
  ↓
Gestion d'erreurs backend
  ↓
Affichage dialogue d'erreur ou succès
```

#### Méthode de dialogue : `_showErrorDialog()`

**Paramètres** :
- `title` : Titre de l'erreur (ex: "Fichier trop volumineux")
- `message` : Message détaillé de l'erreur
- `suggestions` : Liste de solutions possibles

**UI du dialogue** :
- Icône d'erreur rouge
- Titre en gras et rouge
- Message explicatif
- Section "Solutions possibles" avec liste à puces
- Boutons "Fermer" et "Réessayer"

**Exemple de code** :

```dart
_showErrorDialog(
  title: 'Fichier trop volumineux',
  message: 'La taille du fichier (7.45 Mo) dépasse la limite de 5 Mo.',
  suggestions: [
    'Compressez votre image en ligne',
    'Réduisez la résolution de l\'image',
    'Utilisez un compresseur PDF pour les documents',
  ],
);
```

### Backend (NestJS)

**Fichier** : `backend/src/volunteers/volunteers.service.ts`

#### Méthode : `addDocument()`

**Validations effectuées** :
1. Vérification de la taille du buffer
2. Vérification du MIME type

**Messages d'erreur améliorés** :

```typescript
// Taille de fichier
throw new BadRequestException(
  `La taille du fichier (${fileSizeMB} Mo) dépasse la limite de ${maxSizeMB} Mo. 
   Veuillez compresser votre fichier ou choisir un fichier plus petit.`
);

// Type de fichier
throw new BadRequestException(
  `Type de fichier invalide (${file.mimetype}). 
   Formats acceptés : JPG, JPEG, PNG, WebP, PDF uniquement.`
);
```

## Configuration

### Limites de taille

**Frontend** :
```dart
const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
```

**Backend** :
```typescript
const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5MB
```

### Types de fichiers acceptés

**Frontend** :
```dart
allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf']
```

**Backend** :
```typescript
const ALLOWED_MIMES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
];
```

## Interface utilisateur

### Dialogue d'erreur

**Apparence** :
- Fond blanc avec ombre
- Icône d'erreur rouge (28px)
- Titre en rouge et gras (18px)
- Message en noir (16px)
- Section "Solutions possibles" en gras (15px)
- Liste à puces avec puces colorées (couleur primaire)
- Deux boutons : "Fermer" (TextButton) et "Réessayer" (ElevatedButton)

**Comportement** :
- Le bouton "Réessayer" rouvre automatiquement le file picker avec le même type de document
- Le dialogue est scrollable pour les longues listes de suggestions
- Fermeture automatique après une action réussie

### Message de succès

**SnackBar** :
```dart
SnackBar(
  content: Text('✅ Document ajouté avec succès'),
  backgroundColor: Colors.green,
)
```

## Améliorations par rapport à l'ancienne version

### Avant

❌ Messages génériques : "Taille max 5 Mo"
❌ Pas de contexte sur la taille réelle
❌ Pas de suggestions de solutions
❌ Simples SnackBars qui disparaissent rapidement
❌ Pas de distinction entre types d'erreurs
❌ Pas de bouton "Réessayer"

### Après

✅ Messages détaillés avec contexte
✅ Affichage de la taille réelle du fichier
✅ Suggestions concrètes et actionnables
✅ Dialogues persistants avec informations complètes
✅ Détection intelligente des types d'erreurs
✅ Bouton "Réessayer" pour faciliter la correction
✅ Validation côté frontend ET backend
✅ Messages d'erreur en français
✅ Icônes et couleurs pour guider l'utilisateur

## Cas d'usage

### Scénario 1 : Upload d'une image trop grande

1. Volontaire sélectionne une photo de 8 Mo
2. Le système détecte que la taille dépasse 5 Mo
3. Un dialogue s'affiche :
   - **Titre** : "Fichier trop volumineux"
   - **Message** : "La taille du fichier (8.00 Mo) dépasse la limite de 5 Mo."
   - **Suggestions** : Liste de 4 solutions
4. Le volontaire clique sur "Fermer"
5. Il compresse sa photo en ligne
6. Il clique sur "Réessayer" (ou sur le bouton d'upload)
7. L'upload réussit

### Scénario 2 : Upload d'un fichier Word (.docx)

1. Volontaire tente d'uploader un fichier .docx
2. Le système détecte que l'extension n'est pas autorisée
3. Un dialogue s'affiche :
   - **Titre** : "Type de fichier invalide"
   - **Message** : "Le format .docx n'est pas accepté."
   - **Suggestions** : Formats acceptés et conseil de conversion
4. Le volontaire convertit son document en PDF
5. Il réessaie et l'upload réussit

### Scénario 3 : Problème de connexion

1. Volontaire sélectionne un fichier valide
2. L'upload démarre mais échoue à cause d'une perte de connexion
3. Un dialogue s'affiche :
   - **Titre** : "Erreur de connexion"
   - **Message** : "Impossible de se connecter au serveur."
   - **Suggestions** : Vérifier connexion, réessayer, contacter support
4. Le volontaire vérifie sa connexion WiFi
5. Il clique sur "Réessayer"
6. L'upload réussit

## Tests

### Tests manuels à effectuer

1. **Test taille de fichier** :
   - Uploader une image > 5 Mo
   - Vérifier que le message affiche la taille exacte
   - Vérifier que les suggestions sont affichées
   - Compresser l'image et réessayer

2. **Test type de fichier** :
   - Uploader un fichier .txt
   - Vérifier le message d'erreur
   - Uploader un fichier .docx
   - Vérifier le message d'erreur
   - Uploader un PDF valide et vérifier le succès

3. **Test bouton "Réessayer"** :
   - Provoquer une erreur
   - Cliquer sur "Réessayer"
   - Vérifier que le file picker s'ouvre avec le bon type

4. **Test connexion réseau** :
   - Désactiver le WiFi pendant l'upload
   - Vérifier le message d'erreur de connexion
   - Réactiver le WiFi et réessayer

5. **Test fichiers valides** :
   - Uploader une image JPG < 5 Mo
   - Uploader une image PNG < 5 Mo
   - Uploader un PDF < 5 Mo
   - Vérifier les messages de succès

### Tests automatisés (suggestions)

```dart
testWidgets('Shows detailed error for large file', (WidgetTester tester) async {
  // Mock file picker to return large file
  // Verify error dialog appears
  // Verify error message contains file size
  // Verify suggestions list is shown
});

testWidgets('Shows error for invalid file type', (WidgetTester tester) async {
  // Mock file picker to return .txt file
  // Verify error dialog appears
  // Verify correct suggestions are shown
});
```

## Ressources pour les utilisateurs

### Sites de compression recommandés

**Images** :
- https://tinypng.com - Compression PNG et JPG
- https://compressjpeg.com - Compression JPEG
- https://squoosh.app - Compression d'images (Google)
- https://imagecompressor.com - Multi-format

**PDF** :
- https://smallpdf.com/compress-pdf - Compresseur PDF
- https://www.ilovepdf.com/compress_pdf - Compression PDF
- https://www.pdf2go.com/compress-pdf - PDF2GO

### Applications mobiles

**iOS** :
- Photo Compress & Resize
- PDF Compressor
- Compress Photos & Pictures

**Android** :
- Photo & Picture Resizer
- PDF Compressor
- Image Size Reducer

## Maintenance

### Ajouter un nouveau type d'erreur

1. **Backend** : Ajouter la logique de détection
2. **Frontend** : Ajouter le pattern dans le `catch` de `_pickAndUpload`
3. **Créer le message et les suggestions**
4. **Tester le scénario**

### Modifier les limites

1. **Modifier les constantes** :
   - Frontend : `_maxFileSizeBytes`
   - Backend : `MAX_FILE_SIZE_BYTES`
2. **Mettre à jour les messages d'erreur**
3. **Mettre à jour la documentation Swagger**
4. **Tester avec des fichiers limites**

## Conclusion

Ce système de gestion d'erreurs améliore considérablement l'expérience utilisateur en :
- Fournissant des informations claires sur les erreurs
- Proposant des solutions concrètes et actionnables
- Facilitant la correction avec le bouton "Réessayer"
- Éduquant les utilisateurs sur les formats et tailles acceptés

Les volontaires peuvent désormais résoudre rapidement les problèmes d'upload sans avoir à contacter le support.
