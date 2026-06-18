# TaskTeam — To-Do List collaborative (Flutter + Spring Boot)

Application mobile Flutter, architecture **MVC**, connectée à un
backend **Spring Boot** qui persiste les données dans **MySQL** via
une API REST sécurisée par **JWT**. *(SQLite a été retiré : il n'y a
plus aucun stockage local — toute la donnée vit côté backend.)*

## ⚙️ Configuration obligatoire avant de lancer l'app

Ouvre `lib/services/api_service.dart` et remplace la constante
`baseUrl` par l'adresse IP **locale** de la machine qui fait tourner
ton backend Spring Boot :

```dart
static const String baseUrl = 'http://192.168.1.100:8080/api';
```

- Trouve ton IP locale avec `ipconfig` (Windows) ou `ifconfig` / `ip a`
  (macOS/Linux) — cherche l'adresse de ton réseau Wi-Fi (souvent
  `192.168.x.x`).
- **N'utilise pas `localhost`** : sur un appareil physique, `localhost`
  désignerait le téléphone lui-même, pas ton ordinateur.
- Vérifie que ton pare-feu autorise les connexions entrantes sur le
  port `8080`, et que le téléphone est sur le **même réseau Wi-Fi**
  que l'ordinateur.
- Spring Boot doit écouter sur toutes les interfaces (comportement par
  défaut, sauf si `server.address=127.0.0.1` est explicitement
  configuré dans `application.properties`).

### 📱 Android : autoriser le HTTP en clair (obligatoire)

Depuis Android 9 (API 28), une application ne peut **pas** faire
d'appel HTTP non chiffré par défaut — seul HTTPS est autorisé. Comme
ton backend tourne en `http://` sur le réseau local, il faut lever
cette restriction après `flutter create` :

Ouvre `android/app/src/main/AndroidManifest.xml` et ajoute l'attribut
`usesCleartextTraffic` sur la balise `<application>`, ainsi que la
permission Internet si elle n'est pas déjà présente :

```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="taskteam"
        android:usesCleartextTraffic="true"
        ...>
```

*(C'est suffisant pour le développement/la démo. En production, on
restreindrait plutôt ce comportement à une IP précise via un
`network_security_config.xml`, mais ce n'est pas nécessaire ici.)*

## ✅ Fonctionnalités

- Inscription (`POST /api/auth/register`) et connexion par e-mail /
  mot de passe (`POST /api/auth/login`, JWT)
- Créer / modifier / supprimer une tâche (titre, description, échéance)
- Marquer une tâche comme "terminée" (`PATCH /api/tasks/{id}/complete`)
- Toutes les données persistées côté backend (MySQL), aucune base
  locale
- Onglet **Communauté** avec deux sources :
  - **Équipe** : tâches des autres utilisateurs (`GET /api/tasks`)
  - **Externe** : `GET /api/external-tasks` (proxy géré par ton
    `ExternalTaskService`)

## 🏗️ Architecture MVC

```
lib/
├── models/          → MODEL : structures de données
│   ├── task.dart            (mappe titre/description/dateEcheance/terminee/user)
│   ├── app_user.dart        (id/username/email)
│   └── external_task.dart   (parsing tolérant de /api/external-tasks)
│
├── services/        → MODEL : accès réseau
│   ├── api_service.dart        (HTTP vers le backend Spring Boot)
│   └── session_service.dart    (SharedPreferences — token JWT, identité)
│
├── controllers/     → CONTROLLER : logique métier + état (Provider)
│   ├── auth_controller.dart
│   ├── task_controller.dart
│   └── community_controller.dart
│
├── views/           → VIEW : écrans et widgets (UI uniquement)
│   ├── auth/login_screen.dart, register_screen.dart
│   ├── tasks/task_list_screen.dart, task_form_screen.dart
│   ├── community/community_screen.dart   (onglets Équipe / Externe)
│   ├── profile/profile_screen.dart
│   └── widgets/ (TaskCard, EmptyState...)
│
├── theme/, utils/
└── main.dart
```

## 🔑 Comment l'identité de l'utilisateur est gérée

Ton `AuthResponse` ne contient que le `token` JWT — pas l'utilisateur.
Comme `GET /api/tasks` renvoie toutes les tâches avec leur `user`
imbriqué, l'app retrouve l'identité complète (id, username) de deux
façons :

1. **À l'inscription** : la réponse de `/api/auth/register` contient
   déjà l'objet `User` complet (avec son `id`) → utilisé immédiatement.
2. **À la connexion** : l'app charge `GET /api/tasks` et cherche une
   tâche dont `user.email` correspond à l'e-mail saisi au login, pour
   en déduire l'`id`.

**Limite connue** : un utilisateur qui se connecte sans avoir encore
aucune tâche (compte créé hors de l'app, ou app réinstallée) ne sera
identifié qu'après la création de sa première tâche. Pour fermer ce
cas proprement, le plus simple est d'ajouter un petit endpoint côté
backend, par exemple :

```java
@GetMapping("/me")
public User me(@AuthenticationPrincipal User user) {
    return user;
}
```

(à ajouter dans `AuthController`, mappé sur `/api/auth/me`) — dis-moi
si tu veux que je l'intègre côté Flutter une fois ajouté.

## ⚠️ Recommandation sécurité (backend)

`TaskController.createTask` / `updateTask` acceptent un objet `Task`
complet du client, y compris son champ `user`. Rien n'empêche
aujourd'hui un client d'attribuer une tâche à un autre utilisateur en
modifiant simplement le JSON envoyé. Il serait préférable que
`TaskService` ignore le `user` envoyé par le client et assigne
systématiquement l'utilisateur authentifié (récupéré depuis le
contexte de sécurité Spring), notamment pour `createTask`.

## 🚀 Installation

```bash
flutter create taskteam
cd taskteam
# copie lib/ et pubspec.yaml de ce livrable dans le projet généré
flutter pub get
flutter run
```

## 📦 Dépendances principales

| Package | Rôle |
|---|---|
| `provider` | Gestion d'état (Controllers) |
| `http` | Appels API REST vers le backend Spring Boot |
| `shared_preferences` | Persistance du token JWT et de l'identité |
| `intl` + `flutter_localizations` | Dates en français |
| `google_fonts` | Typographie (Space Grotesk + Inter) |
