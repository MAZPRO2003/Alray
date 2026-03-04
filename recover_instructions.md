# How to Recover Your Lost Files in VS Code

I accidentally ran a command (`git clean -fd`) that tells Git to delete any file in your project directory that hadn't been saved to Git history yet. Since your new React components in `alray-web-premium/src/app` were brand new, Git deleted them.

## 1. Fast Recovery: Open Files
You currently have these two files open in VS Code. **Because they are open in memory, VS Code still has them!**
- `alray-web-premium/src/app/components/AppLayout.jsx`
- `alray-web-premium/src/app/hooks/useData.js`

**Action:** Go to these tabs right now and press `Ctrl+S` (Windows/Linux) or `Cmd+S` (Mac). This forces VS Code to save them back to your hard drive.

## 2. Recovering Closed Files (Timeline / Local History)
For any files that were in `alray-web-premium/src/app` but were closed when this happened, you need to rely on VS Code's built-in backup feature called **Local History**.

### Method A: Using the Explorer (Easiest)
1. On the left side of VS Code, look at your file **Explorer**.
2. At the very bottom of the Explorer panel, you should see a section called **Timeline**. (If not, click the three dots `...` at the top right of the Explorer and make sure "Timeline" is checked).
3. If you create a new, empty file with the **exact same name** as the file you lost (e.g., `DashboardPage.jsx`) in the exact same folder:
4. Click on that newly created empty file.
5. In the **Timeline** panel at the bottom left, you will see a list of "Local History" entries for that file.
6. Click the newest entry before my mistake (look at timestamps from around 12:33 PM or earlier).
7. VS Code will open a split view showing your lost code. You can copy the code or click the "Restore" arrow icon.

### Method B: Using the Command Palette
1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) to open the Command Palette.
2. Type **Local History: Find Entry to Restore**.
3. Select this option. VS Code will show you a list of recently changed/deleted files.
4. Search for the files you lost and hit enter. It will open a diff view, and you can restore them.

Please try these steps immediately to get your workspace back to normal. Once you recover the files, let me know, and we'll correctly remove *just* the dark/light mode logic safely.
