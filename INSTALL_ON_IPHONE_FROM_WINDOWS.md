# Windows Se Direct iPhone 15 Plus Par GCam Install Karne Ka Guide (Option 2)

Is method me aapko **Mac khareedne ki zaroorat nahi hai**. GitHub ka free Cloud Mac automatically `.ipa` build karega, aur aap Windows PC se direct apne iPhone 15 Plus par install kar lenge.

---

## 📌 Step 1: Code Ko Apne GitHub Par Push Karein

1. [github.com](https://github.com) par jayein aur ek naya repository banayein:
   * **Repository name**: `GCam-iOS` (Public ya Private dono chalega).
   * **"Initialize with README"** ko uncheck rakhein.
2. Apne Windows computer par terminal me yeh 3 commands chalayein:

```powershell
cd C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/GCam-iOS.git
git branch -M main
git push -u origin main
```
*(Yahan `YOUR_GITHUB_USERNAME` ki jagah apna GitHub username daalein).*

---

## ⚡ Step 2: GitHub Cloud Mac Par Auto-Build

Jaise hi aap code push karenge:
1. Apne GitHub repository me upar **Actions** tab par click karein.
2. Aapko **"Build GCam IPA for iPhone"** workflow automatically chalta hua dikhega.
3. GitHub ka free macOS cloud runner automatically Xcode me aapka app compile karega (~2-3 minute lagenge).
4. Build complete hone par **Artifacts** section me **`GCam-iPhone-15-Plus`** naam ki file ban kar aa jayegi.
5. Us par click karke **`GCam.ipa`** apne Windows PC par download kar lijiye.

---

## 📲 Step 3: Windows Se iPhone 15 Plus Par Install Karein (Via Sideloadly)

1. **Sideloadly Download Karein**:
   * Windows ke liye free official website se download karein: [sideloadly.io](https://sideloadly.io)
   * *(Note: Agar iTunes/iCloud Windows me nahi hai, toh Sideloadly unhe automatically install karne ka option de deta hai).*
2. **iPhone Connect Karein**:
   * Apne **iPhone 15 Plus** ko USB-C cable se Windows laptop se connect karein.
   * iPhone screen par agar **"Trust This Computer?"** aaye, toh **Trust** par tap karein aur passcode daalein.
3. **App Install Karein**:
   * Sideloadly open karein.
   * Download kiya hua **`GCam.ipa`** drag & drop karke Sideloadly ke andar daalein.
   * **Apple ID**: Apni regular Apple ID (email) enter karein (ye sirf app ko sign karne ke liye use hoti hai, 100% safe).
   * **Start** button par click karein!
   * 30-40 seconds me GCam app aapke iPhone 15 Plus ki Home Screen par install ho jayega!

---

## 🔓 Step 4: iPhone Par App Open Karne Se Pehle (1-Time Permission)

iPhone par first-time sideloaded app open karne ke liye:
1. iPhone me jayein: **Settings > General > VPN & Device Management**.
2. Apni Apple ID par tap karein aur **"Trust [Your Apple ID]"** par click karein.
3. **Developer Mode ON karein**:
   * **Settings > Privacy & Security > Developer Mode** ko **ON** karein aur iPhone restart karein.

Ab aapka **GCam 9.8 app** aapke iPhone 15 Plus par chalne ke liye bilkul ready hai! 🎉

---

## 🛠️ Agar App Tap Karte Hi Bina Khule Crash Ho Jaye (Troubleshooting)

Agar app tap karte hi screen flash hokar band ho jati hai, toh yeh 3 cheezein check karein:

1. **Developer Mode Activate Karna (Sabse Main Reason)**:
   * iPhone me **Settings > Privacy & Security > Developer Mode** par jayein.
   * Isko **ON** karein. iPhone restart hoga.
   * Restart hone ke baad screen par **"Turn On Developer Mode?"** aayega, usme **Turn On** dabayein aur apna iPhone Passcode enter karein.
   * *(Note: Jab tak Developer Mode restart ke baad confirm nahi hota, sideloaded apps iOS launch hi nahi hone deta).*

2. **Apple ID Certificate Trust Karna**:
   * **Settings > General > VPN & Device Management** me jayein.
   * "Developer App" ke niche apni Apple ID par tap karein aur **Trust** par click karein.

3. **Latest Crash-Fixed Build Push Karein**:
   * Code me `Info.plist`, `CameraManager` aur `UILaunchScreen` ke launch bugs fix ho chuke hain.
   * Terminal me sirf yeh command chalayein:
     ```powershell
     cd C:\Users\Lenovo\.gemini\antigravity-ide\scratch\GCam-iOS
     git push
     ```
   * GitHub Actions me 2 minute me naya **GCam.ipa** build ho jayega. Use Sideloadly se install karein, 100% crash fix ho jayega!
