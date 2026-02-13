# Configuration des Permissions Caméra

Pour que la vérification par photo fonctionne, vous devez configurer les permissions de caméra sur iOS et Android.

## 📱 iOS (Info.plist)

Ajoutez ces clés dans `frontend/ios/Runner/Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>CogniCare a besoin d'accéder à votre caméra pour vérifier la prise de médicaments</string>
<key>NSMicrophoneUsageDescription</key>
<string>CogniCare a besoin d'accéder au microphone pour enregistrer des vidéos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>CogniCare a besoin d'accéder à vos photos pour sauvegarder les preuves de prise de médicaments</string>
```

## 🤖 Android (AndroidManifest.xml)

Ajoutez ces permissions dans `frontend/android/app/src/main/AndroidManifest.xml` :

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions caméra -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    
    <!-- Feature caméra (optionnel mais recommandé) -->
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>

    <application>
        <!-- Votre configuration existante -->
    </application>
</manifest>
```

## 🔧 Installation du Package

Le package `image_picker` a déjà été ajouté au `pubspec.yaml`. Pour l'installer :

```bash
cd frontend
flutter pub get
```

## 📝 Notes Importantes

### iOS
- **Xcode 14+** requis pour les dernières versions
- Les descriptions sont **obligatoires**, sinon l'app sera rejetée
- Testez sur un **appareil réel** (simulateur a des limitations caméra)

### Android
- **Android 6.0 (API 23+)** pour les permissions runtime
- Les permissions sont demandées automatiquement par `image_picker`
- Testez sur un **appareil réel** (émulateur peut nécessiter config supplémentaire)

## ✅ Test de la Fonctionnalité

1. **Installez l'app** sur un appareil réel
2. **Ajoutez une tâche "Take Medicine"** depuis le dashboard
3. **Allez à la routine quotidienne**
4. **Cliquez sur le checkbox** de la tâche médicament
5. **Acceptez les permissions** caméra si demandé
6. **Prenez une photo** selfie
7. **Validez** → La tâche se coche avec preuve enregistrée

## 🐛 Dépannage

### "Permission denied" sur iOS
- Vérifiez que les clés sont bien dans `Info.plist`
- Supprimez l'app et réinstallez pour réinitialiser les permissions
- Vérifiez dans Réglages > Confidentialité > Caméra

### "Camera not available" sur Android
- Vérifiez que les permissions sont dans `AndroidManifest.xml`
- Sur émulateur, configurez une webcam virtuelle
- Vérifiez dans Paramètres > Applications > Permissions

### La caméra ne s'ouvre pas
- Assurez-vous que `flutter pub get` a été exécuté
- Vérifiez les logs : `flutter run --verbose`
- Sur iOS : `pod install` dans le dossier `ios/`

## 📦 Commandes Complètes

```bash
# Frontend
cd frontend
flutter clean
flutter pub get

# iOS (si nécessaire)
cd ios
pod install --repo-update
cd ..

# Lancer l'app
flutter run
```

## 🔐 Sécurité & Confidentialité

- Les photos sont stockées **côté serveur** uniquement
- Les permissions sont demandées **au moment de l'utilisation**
- Les photos peuvent être **supprimées** par les parents
- Aucune photo n'est accessible publiquement
- Les chemins sont **relatifs** et sécurisés
