# ECE49595O eStorage

## .e2

This is the main directory that stores our app files and the configuration files we need.

- **e2.xcodeproj**: A special directory created by Xcode to store all the settings for our project.
  - **project.pbxproj**: Contains all the settings and configurations for our iOS app project.
  - **xcuserdata**: Contains user-specific settings and configurations for our project.
  - **project.xcworkspace**: Represents the Xcode workspace for our project.
  - **xcshareddata**: Contains shared data files used by all team members collaborating on the Xcode project.
  
- **e2**: Directory that contains code files, UI design data ("Assets.xcassets"), and preview content.
  - **AddItemView.swift**: Contains the UI code and functions for adding food items to our storage list.
  - **BarCodeCameraView.swift**: Handles the functions associated with barcode UI and functions to deal with the barcode lookup API.
  - **CameraView.swift**: Tests camera availability, not directly connected to our app.
  - **ContentView.swift**: Old main page of our app, which contains the storage lists and functions such as deleting items, recipe recommendations, etc.
  - **Item.swift**: Contains the base class of our food items.
  - **ItemDetailView.swift**: Contains UI code for food item details and functions that connect to notification settings.
  - **MainView.swift**: Latest file to control our app life cycle and also has control of the main view of our app.
  - **NotificationSettingView.swift**: Contains the view and functions which allow the user to change notification settings.
  - **Resnet50.mlmodel**: Resnet50 pretrained models for object recognition.
  - **SceneDelegate.swift**: File to control app life cycle. A similar function has been adapted to our MainView.swift.
  - **e2App.swift**: Old file to control our app life cycle and the main view of our app, which is not connected to our app now.
  - **obj_cam.swift and obj_page.swift**: Contains object recognition and text recognition code. Since the code has been adapted to AddItemView.swift, it's not directly connected to the app now.
- **Info.plist**: This file is necessary as it contains the permissions for opening camera features in our app.

## .github/workflows

This directory contain GitHub Actions workflows,CI actions , which are used for automating tasks related to our project.

## .DS_Store files

.DS_Store files are created by macOS to store custom attributes of a folder, such as its icon layout, view settings, and other metadata. They are not necessary for our project and can be safely ignored.
