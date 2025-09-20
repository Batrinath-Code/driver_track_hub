# driver_track_app

A new Flutter project.

## How to Setup Flutter for Building Android without Android Studio

In this guide, we will walk through the steps needed to install Android build tools for Flutter to successfully build an Android application package without Android Studio.

The steps can be roughly divided into:

1. Download Java and set up environment variables
2. Download Android SDK command line tools
3. Download Android SDK using Android SDK command line tools and set up environment variables
4. Download Flutter and set up environment variables

## Download Java and set up environment variables

[Java Download Link Click Me!](https://learn.microsoft.com/en-us/java/openjdk/download)

After Installation Completed.
Set the PATH and JAVA_HOME environment variables. PATH should be appended with the path to the Java’s bin directory. JAVA_HOME should be the root (not bin) directory of the Java location.

``` 

[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Microsoft\jdk-21.0.8.9-hotspot", "Machine") 
$oldPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = "$oldPath;C:\Program Files\Microsoft\jdk-21.0.8.9-hotspot\bin"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

```

## Test it
After restarting PowerShell or your system, run:

` java -version`

## Download Android SDK Command Line Tools
[Android SDK’s command line tools link click me!](https://developer.android.com/studio#command-line-tools-only)

Android SDK uses a specific directory structure to recognize whether its components are installed. Within the Android SDK root, each component must reside in its specificly named subfolder.

```
C:\DeveloperTools\Android\SDK\
└── cmdline-tools\
    └── latest\
        ├── bin\
        └── lib\


```
First, pick a preferred Android SDK location, such as C:\DeveloperTools\Android\SDK. Extract the tool into a your preferred location. Then, move and rename the command line tools folder into the expected subfolder.

```
mkdir C:\DeveloperTools\Android\SDK\cmdline-tools
tar -xf commandlinetools-win-11076708_latest.zip -C C:\DeveloperTools\Android\SDK\cmdline-tools
ren C:\DeveloperTools\Android\SDK\cmdline-tools\cmdline-tools C:\DeveloperTools\Android\SDK\cmdline-tools\latest


```
## Download Android SDK using Android SDK Command Line Tools and Set up Environment Variables

```
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\DeveloperTools\Android\SDK", "Machine")"
```
This should install the platform tools, and if successful, then installation is sound.

## Download Flutter and set up environment variables

[Flutter SDK archive link click me!](https://docs.flutter.dev/install/archive)

`tar -xf flutter.zip -C C:\DeveloperTools\flutter`

Now, set the PATH variable to the bin of flutter directory and FLUTTER_ROOT variable to the root of the flutter directory. For Windows:

```
[System.Environment]::SetEnvironmentVariable("FLUTTER_ROOT", "C:\DeveloperTools\flutter", "Machine")
$oldPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = "$oldPath;C:\DeveloperTools\flutter\bin"
[System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

```