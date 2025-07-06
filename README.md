# NextGen Fitness - Complete Setup Guide

Welcome to the NextGen Fitness project! This guide provides a comprehensive, step-by-step walkthrough for setting up and running the application on your local machine. It is designed for users of all skill levels, including those new to development.

## Project Overview
NextGen Fitness is an AI-powered fitness application that provides personalized workout plans, diet recommendations, and comprehensive fitness tracking. The application features:

### Core Features:
- **AI-generated personalized workout plans** based on fitness goals and preferences
- **Comprehensive diet plan system** with meal recommendations and nutrition tracking
- **Food recognition and meal scanning** using AI technology
- **Exercise library** with detailed instructions and video demonstrations
- **Progress tracking and analytics** for both workouts and diet
- **User profile management** with BMI calculation and goal setting
- **Admin dashboard** for user management and system monitoring

### Advanced Features:
- **AI-powered chatbot** for fitness and nutrition guidance
- **Meal logging and nutrition analysis**
- **Recipe library** with ingredient management
- **Grocery shop locator** for healthy food shopping
- **User engagement analytics** and reporting
- **Feedback system** with admin response capabilities
- **Notification system** for workout reminders
- **Dietary preference management** and allergen tracking
- **Workout plan customization** and progress monitoring

### Technical Features:
- **Secure user authentication** and role-based access control
- **SQLite database** for data persistence
- **RESTful API backend** with Flask
- **Cross-platform Flutter frontend** (Android-focused)
- **Image processing** and food recognition integration
- **Google AI integration** for intelligent recommendations

## Project Structure
The repository is organized into three main parts: Readme.md, the backend server and the frontend application.

```
/capstone
├── Readme.md
├── /backend
│   ├── NextGenFItness.py     # Main Flask application file
│   ├── requirements.txt      # Backend Python dependencies
│   ├── NextGenFitness.db     # SQLite database file
│   └── ...                   # Other backend files
│
└── /frontend
    ├── /lib
    │   └── main.dart         # Main Flutter application entry point
    ├── pubspec.yaml          # Frontend Flutter dependencies
    └── ...                   # Other frontend files
```

**Last Updated:** July 2025  
**Compatibility:** Windows 10/11 (64-bit), Android Emulator Only

## Quick Start (For Experienced Developers)
If you're familiar with development environments, you can skip to the essential steps:
1. Install Python 3.x, Flutter SDK, and Android Studio
2. Clone: `git clone https://github.com/TngEr0425/capstone.git`
3. Backend: `cd backend && pip install -r requirements.txt && python NextGenFItness.py`
4. Frontend: `cd frontend && flutter pub get && flutter run`

**Note**: This document is extensive. Readers may use the search function (Ctrl + F) to navigate to specific sections.

Table of Contents
1.	Prerequisites
   A. System Requirements
   B. Software Requirements
   C. Developer Mode Requirement
2.	Software Installation and Verification
   A. Git Version Control
   B. Python Interpreter
   C. Flutter SDK & Dart
   D. Android Studio and Emulator
   E. Visual Studio Code
3.	Project Setup
   Step 1: Download the Project Code
   Step 2: Set Up the Backend Dependencies
   Step 3: Set Up the Frontend Dependencies
4.	Running the Application
   Step 1: Start the Backend Server
   Step 2: Launch the Android Emulator
   Step 3: Run the Frontend Application
5.	Admin Dashboard Access
6.	Troubleshooting during Project Setup
   A. Command Prompt Issues
   B. Git Issues
   C. Python Issues
   D. Flutter Issues
   E. Android Studio Issues
   F. VS Code Issues
   G. Network and Connection Issues
   H. File and Folder Issues
   I. Performance Issues
   J. General Tips for Beginners
   K. When to Ask for Help
7.	Troubleshooting during Running Application
   A. API Key Issues
   B. Application Crashes
   C. Network and Connection Issues
   D. Data and Storage Issues
   E. Feature-Specific Issues
   F. Performance Issues
   G. User Interface Issues
   H. How to Report Issues
   I. Emergency Contact
8.	Frequently Asked Questions (FAQ)
9.	Contact Information

## 1. Prerequisites
Before you begin, please ensure your system meets the following requirements:

### A. System Requirements
**Minimum Requirements:**
- **Operating System:** Windows 10 or newer (64-bit)
- **Processor:** Intel Core i3 or AMD equivalent (2.0 GHz or faster)
- **RAM:** 8 GB (16 GB recommended)
- **Disk Space:** At least 5 GB of free disk space for the required tools and project files
- **Internet Connection:** Required for downloading software and project files
- **Graphics:** Integrated graphics card (dedicated GPU recommended for better emulator performance)

**Recommended Requirements:**
- **Operating System:** Windows 11 (64-bit)
- **Processor:** Intel Core i5 or AMD equivalent (3.0 GHz or faster)
- **RAM:** 16 GB or more
- **Disk Space:** 10 GB of free disk space
- **Graphics:** Dedicated graphics card with 2GB+ VRAM

### B. Software Requirements
- **Git** (latest version)
- **Python 3.8** or higher
- **Flutter SDK** (latest stable version)
- **Android Studio** (latest version)
- **Visual Studio Code** (recommended)

### C. Developer Mode Requirement
**IMPORTANT:** Before proceeding with the installation, you must enable Developer Mode on your Windows device.
1. **Open Windows Settings:** Press Windows key + I
2. **Navigate to System:** Click on "System" in the left sidebar
3. **Find Developer Options:** Scroll down and click on "For developers"
4. **Enable Developer Mode:** Toggle the switch next to "Developer Mode" to turn it ON
5. **Restart if Required:** Windows may prompt you to restart your computer. If so, restart and then continue with the installation process.

**Note:** Developer Mode is required for running Android emulators and development tools on Windows 10/11.

## 2. Software Installation and Verification
This section will guide you through installing and verifying all the necessary software.

### A. Git Version Control
Git is used to download (clone) the project files from GitHub.
1. **Install:** Go to git-scm.com/downloads, download the installer for Windows, and run it. You can safely accept all the default settings during installation.
2. **Verify:** Open a new Command Prompt (search for cmd in the Start Menu) and type the following command, then press Enter:
   ```
   git --version
   ```
   You should see an output like `git version 2.xx.x.windows.x`, which confirms it's installed correctly.

### B. Python Interpreter
The backend of our application is built with Python.
1. **Install:** Go to python.org/downloads and download the latest stable version of Python 3.
2. **Run the installer.** **CRUCIAL STEP:** On the first screen of the installer, check the box that says "Add Python to PATH" before clicking "Install Now".
3. **Verify:** Open a new Command Prompt and type:
   ```
   python --version
   ```
   You should see an output like `Python 3.x.x`, confirming a successful installation.

### C. Flutter SDK & Dart
Flutter is the framework for the user interface, and it uses the Dart programming language.
1. **Install:** Visit the official Flutter documentation at docs.flutter.dev/get-started/install. Follow the instructions for Windows carefully. This involves downloading a .zip file, extracting it (e.g., to C:\flutter), and updating your "Path" environment variable.
2. **Verify:** Open a new Command Prompt and run the Flutter Doctor tool. This command checks your environment and reports on the status of your installation.
   ```
   flutter doctor
   ```
   Don't worry if it shows some issues initially. We will resolve them in the next steps. The important part is that the flutter command is recognized.

### D. Android Studio & Emulator
We use Android Studio to get the Android SDK and to create a virtual device (emulator) to run the app.
1. **Install:** Go to the Android Studio download page (https://developer.android.com/studio), download the installer, and run it. Accept the default settings.
2. **Configure:** After installation, open Android Studio. It will guide you through a setup wizard. Choose "Standard" setup to get all the necessary components, including the Android SDK.
3. **Run Flutter Doctor Again:** Open a new Command Prompt and run flutter doctor again. It should now show a checkmark next to "Android toolchain". If not, follow the instructions in Troubleshooting section.

### E. Visual Studio Code (Recommended Editor)
While you can use any editor, we recommend VS Code for its excellent Flutter support.
1. **Install:** Download VS Code from code.visualstudio.com and install it.
2. **Install Extensions:**
   - Open VS Code.
   - Click the Extensions icon on the left-hand sidebar (it looks like four squares).
   - Search for and install the Flutter extension from Dart Code. Installing this will also automatically install the required Dart extension.

## 3. Project Setup
Now that all the necessary software is installed, it's time to download the project files from GitHub and prepare them for use.

### Step 1: Download the Project Code
You have two options to download the project files:

#### Option A: Download from Moodle (Recommended for Students)
1. **Access Moodle:** Go to the following link: https://lms2.apiit.edu.my/mod/assign/view.php?id=881762
2. **Download Project Files:** Download the project folder from the Moodle assignment
3. **Extract Files:** Extract the downloaded folder to your desired location (e.g., C:\Projects)
4. **Verify the Download:** You should now see a capstone folder in your projects directory

#### Option B: Clone from GitHub (For Developers)
1. **Create a Project Folder:** First, decide where you want to save the project. It's good practice to have a dedicated folder for your projects, for example, C:\Projects. Create this folder if it doesn't exist.
2. **Open Command Prompt in Folder:** Navigate to your newly created projects folder. A simple way is to open the folder in Windows File Explorer, click on the address bar at the top, type cmd, and press Enter. This will open a Command Prompt directly in that location.
3. **Clone the Repository:** In the Command Prompt window, type the following command and press Enter:
   ```
   git clone https://github.com/TngEr0425/capstone.git
   ```
   This command contacts GitHub and downloads the entire capstone project into a new folder with the same name.
4. **Verify the Download:** You should now see a capstone folder inside your projects directory. You can navigate into it by running `cd capstone` in the same terminal.

### Step 2: Set Up the Backend Dependencies
The backend requires several Python libraries to function. We will install them using a requirements.txt file that lists all the necessary packages.
1. **Navigate to Backend Folder:** In your Command Prompt, make sure you are inside the capstone folder, then move into the backend folder:
   ```
   cd backend
   ```
2. **Install Dependencies:** Run the following command. This tells Python's package manager (pip) to read the requirements.txt file and install every package listed inside it.
   ```
   pip install -r requirements.txt
   ```
   You will see text scrolling as the packages are downloaded and installed. Wait for this process to complete without errors.

### Step 3: Set Up the Frontend Dependencies
Similar to the backend, the Flutter frontend also has its own set of packages that need to be installed.
1. **Navigate to Frontend Folder:** In your Command Prompt, navigate from your current location (capstone/backend) back to the parent capstone folder and then into the frontend folder.
   ```
   cd ../frontend
   ```
2. **Install Dependencies:** Run the following command. This command looks for the pubspec.yaml file in the Flutter project and downloads all the required packages.
   ```
   flutter pub get
   ```
   You should see a message like `Process finished with exit code 0` when it's done. Your project is now fully set up and ready to be run.

## 4. Running the Application
The application consists of two parts: the backend server and the frontend app. They must be run in the correct order.

### Step 1: Start the Backend Server
1. Open a Command Prompt and navigate to the capstone/backend directory.
2. Run the following command to start the Python server:
   ```
   python NextGenFItness.py
   ```
3. The server is now running. You will see some output in the terminal. **DO NOT CLOSE THIS TERMINAL WINDOW.**

### Step 2: Launch the Android Emulator
1. Open Android Studio.
2. On the welcome screen, click "More Actions" > "Virtual Device Manager".
3. Click the Play icon (▶) next to a virtual device to launch it. If you don't have one, create one using the "Create device" button.
4. Wait for the emulator to fully boot up and show the Android home screen.

### Step 3: Run the Frontend Application
1. Open a new Command Prompt or Terminal window (leaving the backend server running).
2. Navigate to the frontend project folder: capstone/frontend.
3. If using VS Code (Recommended):
   - Open the capstone/frontend folder in VS Code.
   - Ensure the emulator you launched is selected in the bottom-right corner of VS Code.
   - Go to Run > Start Debugging (or press F5).
4. If using Command Prompt:
   - Run the command:
   ```
   flutter run
   ```
5. The first time you run it, it will take a few minutes to build and install the app onto the emulator. Once complete, the NextGen Fitness app will launch automatically.
**If all steps were followed correctly, the application will launch on the emulator. The setup is now complete.**

## 5. Admin Dashboard Access
The NextGen Fitness application includes an admin dashboard for user management and system monitoring. Since admin account registration is not available through the regular user interface, use the following credentials to access the admin dashboard:

### Admin Login Credentials:
- **Username:** apu
- **Password:** neo123

### How to Access Admin Dashboard:
1. **Launch the Application:** Follow the steps in Section 4 to start the application
2. **Navigate to Login:** Use the login screen in the application
3. **Enter Admin Credentials:** Use the username and password provided above
4. **Access Admin Features:** Once logged in with admin credentials, you will have access to:
   - User management and monitoring
   - System analytics and reporting
   - Feedback management

**Note:** Admin accounts have elevated privileges and access to sensitive system information. Use these credentials responsibly and only for authorized testing or development purposes.

## 6. Troubleshooting during Project Setup
This section helps you solve common problems you might encounter while setting up and running the application. **Don't worry if you run into issues - they're very common, especially for first-time users!**

### A. Command Prompt Issues
**Problem:** "Command not recognized" or "Command not found"
- This usually means the program isn't installed or isn't in your computer's PATH.
- **Solution:** Make sure you've installed the software correctly and restarted your Command Prompt after installation.
- If you're still having trouble, try closing all Command Prompt windows and opening a new one.

**Problem:** "Access denied" when running commands
- This means Windows is blocking the command for security reasons.
- **Solution:** Right-click on Command Prompt in the Start Menu and select "Run as administrator".

### B. Git Issues
**Problem:** "git is not recognized as an internal or external command"
- Git isn't installed or isn't in your PATH.
- **Solution:** Reinstall Git from git-scm.com/downloads and make sure to restart your Command Prompt after installation.

**Problem:** "Repository not found" when cloning
- The repository URL might be incorrect or the repository might be private.
- **Solution:** Double-check the URL: `https://github.com/TngEr0425/capstone.git`
- Make sure you have an internet connection.

### C. Python Issues
**Problem:** "python is not recognized as an internal or external command"
- Python isn't installed or isn't in your PATH.
- **Solution:** Reinstall Python from python.org/downloads and make sure to check "Add Python to PATH" during installation.

**Problem:** "pip is not recognized"
- Pip (Python's package manager) isn't installed.
- **Solution:** Try running: `python -m pip install --upgrade pip`
- If that doesn't work, reinstall Python and make sure to check "Add Python to PATH".

**Problem:** "Permission denied" when installing packages
- Windows is blocking the installation.
- **Solution:** Run Command Prompt as administrator (right-click Command Prompt → "Run as administrator").

### D. Flutter Issues
**Problem:** "flutter is not recognized as an internal or external command"
- Flutter isn't installed or isn't in your PATH.
- **Solution:** Follow the Flutter installation guide again at docs.flutter.dev/get-started/install
- Make sure you've added Flutter to your PATH environment variable.

**Problem:** "flutter doctor" shows red X marks
- Some components aren't properly installed or configured.
- **Solution:** Run flutter doctor and follow the specific instructions it provides for each issue.

**Problem:** "No supported devices connected"
- No Android emulator is running or no physical device is connected.
- **Solution:** Start an Android emulator first (see Section 4, Step 2) or connect a physical Android device with USB debugging enabled.

### E. Android Studio Issues
**Problem:** Android Studio won't open or crashes
- Your computer might not meet the minimum requirements.
- **Solution:** Make sure you have at least 8GB RAM and a 64-bit Windows system.
- Try restarting your computer and opening Android Studio again.

**Problem:** "No virtual devices available"
- You haven't created an Android emulator yet.
- **Solution:** In Android Studio, go to "More Actions" → "Virtual Device Manager" → "Create device" and follow the setup wizard.

**Problem:** Emulator is very slow
- This is normal for first-time users.
- **Solution:** Make sure you have at least 8GB RAM available. Close other programs to free up memory.
- The emulator will be faster after the first few uses.

### F. VS Code Issues
**Problem:** Flutter extension not working
- The Flutter extension might not be installed properly.
- **Solution:** Go to Extensions (Ctrl+Shift+X), search for "Flutter", and reinstall the Flutter extension.

**Problem:** "No device selected" in VS Code
- VS Code can't find your Android emulator.
- **Solution:** Make sure your emulator is running first, then restart VS Code.

### G. Network and Connection Issues
**Problem:** "Connection refused" or "Cannot connect to server"
- The backend server isn't running or there's a network issue.
- **Solution:** Make sure you've started the backend server (`python NextGenFItness.py`) before running the frontend.

**Problem:** "Timeout" errors
- Your internet connection might be slow or unstable.
- **Solution:** Try again when your internet connection is more stable.
- If downloading packages takes too long, you can try using a different network.

### H. File and Folder Issues
**Problem:** "File not found" or "Directory not found"
- You might be in the wrong folder.
- **Solution:** Use the cd command to navigate to the correct folder. For example:
  ```
  cd C:\Projects\capstone\backend
  ```
- Make sure the folder path exists and you've typed it correctly.

**Problem:** "Permission denied" when accessing files
- Windows is blocking access to the files.
- **Solution:** Right-click on the folder → Properties → Security → Edit → Add your username and give it Full control.

### I. Performance Issues
**Problem:** Computer becomes very slow
- Running an emulator and development tools uses a lot of resources.
- **Solution:** Close unnecessary programs, especially web browsers with many tabs.
- Make sure you have at least 8GB RAM and some free disk space.

**Problem:** Emulator takes a long time to start
- This is normal, especially the first time.
- **Solution:** Be patient - it can take 5-10 minutes the first time. Subsequent starts will be faster.

### J. General Tips for Beginners
- **Always restart your Command Prompt** after installing new software
- If something doesn't work, try closing and reopening the program
- Don't be afraid to restart your computer if things get confusing
- **Take screenshots of error messages** to help with troubleshooting
- Make sure your Windows is up to date
- If you're still having trouble, try the steps again from the beginning

### K. When to Ask for Help
If you've tried the solutions above and still can't get the application running:
1. **Take a screenshot** of the error message
2. **Note down what step** you were on when the error occurred
3. **Check the Contact Information** section below for ways to get help

**Remember:** Everyone encounters problems when setting up development environments for the first time. Don't get discouraged - these issues are very common and solvable!

## 7. Troubleshooting during Running Application
This section covers common issues you might encounter while using the NextGen Fitness application after it's been successfully set up and launched.

### A. API Key Issues
**Problem:** "API Key Expired" or "Invalid API Key" error
- This means the application's API key has expired or is no longer valid.
- **What to do:**
  1. **Take a screenshot** of the error message (press PrtScn key on your keyboard)
  2. **Contact us immediately** using the information in Section 9 (Contact Information)
  3. You can also send feedback directly through the application
- **Note:** This is a server-side issue that requires developer attention. Please do not try to fix this yourself.

**Problem:** "API Rate Limit Exceeded"
- The application has made too many requests to the server in a short time.
- **Solution:** Wait a few minutes and try again. If the problem persists, contact us.

### B. Application Crashes
**Problem:** App suddenly closes or crashes
- This can happen due to memory issues or unexpected errors.
- **Solution:** 
  1. Close the app completely (swipe it away from recent apps)
  2. Restart the app
  3. If it keeps crashing, restart your emulator/device
  4. If the problem continues, contact us with details

**Problem:** App freezes or becomes unresponsive
- The app might be processing a large amount of data or experiencing a network issue.
- **Solution:**
  1. Wait 30-60 seconds for the app to respond
  2. If it doesn't respond, force close the app and restart it
  3. Check your internet connection

### C. Network and Connection Issues
**Problem:** "No internet connection" or "Network error"
- The app can't connect to the internet or the backend server.
- **Solution:**
  1. Check your internet connection
  2. Make sure the backend server is still running (see Section 4, Step 1)
  3. If using an emulator, make sure it has internet access
  4. Try restarting the app

**Problem:** "Server not responding" or "Connection timeout"
- The backend server might have stopped or is experiencing issues.
- **Solution:**
  1. Check if the backend server is still running in your Command Prompt
  2. If the server stopped, restart it by running: `python NextGenFItness.py`
  3. If the server is running but still not responding, contact us

### D. Data and Storage Issues
**Problem:** "Cannot save data" or "Storage error"
- The app can't save your workout or diet data.
- **Solution:**
  1. Check if you have enough storage space on your device/emulator
  2. Restart the app and try again
  3. If the problem persists, contact us

**Problem:** Data not loading or showing as empty
- Your saved data might not be loading properly.
- **Solution:**
  1. Check your internet connection
  2. Restart the app
  3. If data is still missing, contact us immediately

### E. Feature-Specific Issues
**Problem:** Workout plans not generating
- The AI workout generation feature might not be working.
- **Solution:**
  1. Check your internet connection
  2. Make sure you've filled in all required information
  3. Try again in a few minutes
  4. If the problem continues, contact us

**Problem:** Diet recommendations not appearing
- The diet recommendation system might be experiencing issues.
- **Solution:**
  1. Check your internet connection
  2. Make sure you've provided all necessary information (age, weight, goals, etc.)
  3. Try refreshing the page or restarting the app
  4. Contact us if the issue persists

**Problem:** Exercise videos not playing
- Video content might not be loading properly.
- **Solution:**
  1. Check your internet connection
  2. Try refreshing the page
  3. If videos still don't play, contact us

### F. Performance Issues
**Problem:** App is very slow or laggy
- The app might be using too much memory or processing power.
- **Solution:**
  1. Close other apps running in the background
  2. Restart the app
  3. If using an emulator, restart it
  4. Make sure your device has enough free memory

**Problem:** App takes a long time to start
- This can happen when the app is loading data or connecting to the server.
- **Solution:**
  1. Be patient - this is normal, especially on first launch
  2. Make sure you have a good internet connection
  3. If it takes more than 2-3 minutes, restart the app

### G. User Interface Issues
**Problem:** Buttons not responding or UI elements not working
- The user interface might be experiencing issues.
- **Solution:**
  1. Try tapping the button again
  2. Restart the app
  3. If the problem continues, contact us

**Problem:** Text or images not displaying properly
- The app's display might be having rendering issues.
- **Solution:**
  1. Restart the app
  2. If using an emulator, try changing the screen resolution
  3. Contact us if the issue persists

### H. How to Report Issues
When reporting any of the above issues, please provide:
1. **A clear description** of what you were trying to do
2. **What error message** you saw (if any)
3. **A screenshot** of the error (press PrtScn key)
4. **What step** you were on when the problem occurred
5. **Your device/emulator information**

### I. Emergency Contact
If the application is completely unusable or you're experiencing critical issues:
- **Contact us immediately** using the information in Section 9
- **Include "URGENT"** in your message subject
- **Provide as much detail** as possible about the issue

**Remember:** Most issues can be resolved by restarting the app or checking your internet connection. If you're unsure about anything, don't hesitate to contact us for help!

## 8. Frequently Asked Questions (FAQ)

**Q: How long does the entire setup process take?**
A: For beginners, expect **1-2 hours total**. For experienced developers, **30-45 minutes**. The longest parts are downloading Android Studio (~15 minutes) and the first emulator startup (~10 minutes).

**Q: Can I use a physical Android device instead of an emulator?**
A: **No**, this application is designed specifically for Android emulator use only. Physical device support is not available due to database connectivity requirements.

**Q: What if I don't have enough disk space?**
A: You can free up space by:
- Uninstalling unused programs
- Clearing temporary files (Windows + R, type `temp` and delete contents)
- Using an external drive for the project (though this may slow performance)

**Q: Do I need to install all the software mentioned?**
A: **Git, Python, Flutter, and Android Studio are required**. VS Code is recommended but optional - you can use any text editor.

**Q: What happens if my computer doesn't meet the minimum requirements?**
A: The application may run slowly or crash frequently. **Consider upgrading your RAM to at least 8GB** for better performance.

**Q: Can I run this on macOS or Linux?**
A: **This guide is specifically for Windows**. For other operating systems, the setup process is different and not covered in this documentation.

**Q: What if the emulator is too slow?**
A: Try these solutions:
- Close other applications to free up RAM
- Increase the emulator's RAM allocation in Android Studio
- Enable hardware acceleration in BIOS (if available)
- Use a lower resolution emulator

**Q: How do I update the application to a newer version?**
A: Pull the latest changes from GitHub:
```
cd capstone
git pull origin main
cd backend && pip install -r requirements.txt
cd ../frontend && flutter pub get
```

**Q: What should I do if I get a "port already in use" error?**
A: This means the backend server is already running. Either:
- Use the existing server (if it's working)
- Close the existing server and restart it
- Change the port in the backend configuration

**Q: Can I use this application without an internet connection?**
A: The initial setup requires internet, but once running, some features may work offline. However, **AI features, food recognition, and data synchronization require internet connectivity**.

**Q: What if I forget my project folder location?**
A: Use Windows Search to find the "capstone" folder, or check your recent Command Prompt history by pressing the up arrow key.

**Q: How do I completely uninstall everything?**
A: To remove all installed software:
- Uninstall Python from Control Panel
- Delete the Flutter folder
- Uninstall Android Studio
- Uninstall VS Code
- Delete the project folder

**Q: What's the difference between the backend and frontend?**
A: The **backend (Python)** handles data processing, AI features, database operations, and API endpoints. The **frontend (Flutter)** is the user interface you interact with.

**Q: Can I contribute to this project?**
A: **Yes!** Contact the development team through the information in Section 9. We welcome bug reports, feature suggestions, and code contributions.

**Q: What if I encounter an error not covered in the troubleshooting sections?**
A: **Take a screenshot** of the error, note what you were doing, and contact us immediately. Include "NEW ISSUE" in your message subject.

**Q: Why is this application Android-only?**
A: The application is designed specifically for Android emulator use to ensure **consistent database connectivity and development environment compatibility**.

**Q: What AI features are included in the application?**
A: The app includes **AI-powered workout plan generation, food recognition for meal scanning, intelligent diet recommendations, and a chatbot for fitness guidance**.

**Q: How do I access the admin features?**
A: Admin features are available to users with admin role (role = 0). **Contact the development team** if you need admin access for testing or development purposes.

**Q: What database does the application use?**
A: The application uses **SQLite database (NextGenFitness.db)** for data persistence, which is why it's designed for emulator use only.

## 9. Contact Information
If you need help with any issues not covered in the troubleshooting sections above, please contact our development team:

**Microsoft Teams / Outlook:**
- TNG KAR MING: tp077627@mail.apu.edu.my
- WONG JIA SEN: tp076184@mail.apu.edu.my
- ONG JYONG VEY: tp077040@mail.apu.edu.my
- ONG JUN XIAN: tp076928@mail.apu.edu.my
- WONG YU HENG: tp076232@mail.apu.edu.my
- RYAN LAU JUN HONG: tp076271@mail.apu.edu.my

**When contacting us, please include:**
1. **A clear description** of your issue
2. **Screenshots** of any error messages
3. **The step** where you encountered the problem
4. **Your device/emulator information**

We aim to respond to all inquiries within **72 hours** during business days.

You can also send feedback directly through the application.

---

## Additional Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Python Documentation](https://docs.python.org/)
- [Android Studio Documentation](https://developer.android.com/studio)
- [Git Documentation](https://git-scm.com/doc)

## Technical Support
For technical issues, please refer to the troubleshooting sections first. If your issue persists, contact the development team with detailed information about your problem.

**Thank you for using NextGen Fitness!**