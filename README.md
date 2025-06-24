#  PlantGuard – Détection de maladies des feuilles (notamment de tomate)

PlantGuard est une application mobile développée en **Flutter**, embarquant un modèle d’intelligence artificielle (**TensorFlow Lite**) pour diagnostiquer **6 types de maladies foliaires** chez la tomate à partir d’images. L’application fonctionne **entièrement hors ligne**, fournit des recommandations phytosanitaires et stocke l’historique localement.

##  Fonctionnalités clés

-  Détection en temps réel de maladies de la tomate à partir d’une simple photo
-  6 classes reconnues :
  - Bacterial Spot
  - Early Blight
  - Healthy
  - Septorial Leaf Spot
  - Leaf Mold
  - Yellow Leaf Curl Virus
-  Modèle CNN converti en `.tflite` pour usage mobile
-  Interface Flutter multilingue (EN/FR)
-  Recommandations phytosanitaires pour chaque maladie
-  Historique local des prédictions
-  Mode **offline** natif (aucune connexion requise)

##  Architecture du projet

```
plant_guard_final/
├── assets/
│   ├── images/                  # Icônes et illustrations
│   ├── models/
│   │   ├── tomato_disease_model.tflite
│   │   └── labels.txt
│   └── language/
│       ├── en.json
│       └── fr.json
├── lib/
│   ├── pages/
│   │   ├── camera_page.dart
│   │   ├── diagnostic_page.dart
│   │   ├── history_page.dart
│   │   ├── history_detail_page.dart
│   │   └── home_page.dart
│   └── main.dart               # Point d'entrée
├── ios/ & android/             # Dossiers natifs
└── build/                      # Dossier de compilation
```

##  Technologies utilisées

| Composant           | Technologie            |
|---------------------|------------------------|
| Frontend            | Flutter (Dart)         |
| Modèle IA           | CNN → TensorFlow Lite  |
| Backend IA embarqué | TFLite (mobile)        |
| Base de données     | SQLite (locale)        |
| Traduction          | `easy_localization`    |

##  Exemple d'utilisation

1. **Lancer l’application**
2. Cliquer sur **"Prendre une photo"**
3. Le modèle TFLite embarqué effectue la classification en local
4. Résultat + recommandation affichés
5. Possibilité de consulter l’historique des prédictions

##  Performances du modèle

- **Accuracy** validation : ~97%
- **Modèle CNN** entraîné sur PlantVillage (6 classes filtrées)
- **Optimisation :**
  - Réduction de taille via quantification
  - Conversion `.h5` → `.tflite`
  - Input 150x150 ou 

##  Lancer le projet Flutter

```bash
flutter pub get
flutter run
```

Assurez-vous d’avoir Flutter installé correctement : https://docs.flutter.dev/get-started/install

##  Compilation APK

```bash
flutter build apk --release
```

Le fichier `.apk` sera généré dans `build/app/outputs/flutter-apk/`.


##  Licence

Ce projet est réalisé à des fins éducatives. Toute réutilisation doit citer l'auteur original.
