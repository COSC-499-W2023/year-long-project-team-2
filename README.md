<picture>
  <img src="https://github.com/COSC-499-W2023/year-long-project-team-2/assets/88886207/d6be51b9-cd11-4dc7-a7a9-e35a95efb27f" alt="FoodHood App Icon" height="80">
</picture>

# FoodHood
FoodHood is a mobile application that allows users to share leftover food with people in need. 

It lets you to create food posts, view nearby food listings available to you, order food, and arrange for pickup at a designated meetup point after placing your order.

> [!WARNING]
> Project is currently under development, see the list of features completed in the design document.

## Local development

1. Make sure the latest version of [Flutter](https://docs.flutter.dev/get-started/install) was installed. For Mac with Homebrew, in command line, type:
  ```bash
  brew install --cask flutter
  ```
2. Fetch latest source code from master branch.
  ```bash
  git clone https://github.com/COSC-499-W2023/year-long-project-team-2
  ```
3. Locate the app folder:
  ```bash
  cd year-long-project-team-2
  cd app
  ```
4. Run the app with Android Studio or VS Code. Or the command line:
  ```bash
  flutter pub get
  flutter run
  ```
  - Ensure Xcode or Android enviroment was setup correctly on your computer. You may also have to setup appropriate iOS and Android Emulators to run on device.
5. To test the flutter project:
  ```bash
  flutter test
  ```
## Project Hierarchy

```
.
├── docs                    # Documentation files (alternatively `doc`)
│   ├── project plan        # Project plan document
│   ├── design              # Getting started guide
│   ├── final               # Getting started guide
│   ├── logs                # Team Logs
│   └── ...          
├── app                     # Source files
├── tests                   # Automated tests 
├── utils                   # Tools and utilities
└── README.md
```
