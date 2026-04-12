# 🧠 AI MindMap

AI MindMap is a multi-module project that combines **Artificial Intelligence**, **Backend API**, and **Mobile App** in one system.

The project is organized as a monorepo containing:

- 🤖 Python AI services
- 🧩 Laravel Backend API
- 📱 Flutter Mobile App

---

## 📁 Project Structure

---

## 🚀 Technologies Used

- Python 🐍 (AI / ML)
- Laravel ⚡ (Backend API)
- Flutter 📱 (Mobile App)
- Git & GitHub 🗂️

---

## ⚙️ Setup Instructions

### 1️⃣ Clone the repository
```bash
git clone https://github.com/USERNAME/ai-mindmap.git
cd ai-mindmap

cd ai-python
python -m venv venv
venv\Scripts\activate   # Windows
pip install -r requirements.txt

cd backend-laravel
composer install
cp .env.example .env
php artisan key:generate
php artisan serve

cd mobile-flutter
flutter pub get
flutter run

create new branch.....
git checkout -b feature-name
git add .
git commit -m "your message"
git push origin feature-name
