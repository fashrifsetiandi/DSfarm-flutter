# Week 01: Foundation & Auth 🚀

> **Status:** 🟡 In Progress  
> **Duration:** Day 1-5  
> **Previous:** None (Starting fresh!)

---

## 🎯 Week Objectives

1. Setup Flutter development environment
2. Integrate Supabase SDK
3. Build Login & Register screens
4. Implement auth state management

---

## 📚 Learning Goals

By end of this week, you should understand:
- [ ] Dart null safety (`?`, `!`, `??`)
- [ ] Widget tree composition
- [ ] StatelessWidget vs StatefulWidget
- [ ] Provider/Riverpod basics
- [ ] Supabase auth flow

---

## ✅ Daily Checklist

### Day 1-2: Project Setup
- [x] Flutter installed via Homebrew
- [x] Project created: `flutter create`
- [x] agents.md added
- [ ] Add dependencies to pubspec.yaml
- [ ] Create folder structure (core/, models/, features/)
- [ ] Setup Supabase client

### Day 3: Auth UI
- [ ] Create `LoginScreen` widget
- [ ] Create `RegisterScreen` widget  
- [ ] Form validation
- [ ] Error handling UI

### Day 4: Auth Logic
- [ ] Supabase signIn method
- [ ] Supabase signUp method
- [ ] Session persistence
- [ ] AuthProvider (Riverpod)

### Day 5: Navigation
- [ ] GoRouter setup
- [ ] Protected routes
- [ ] Redirect logic (login → dashboard)
- [ ] Test full auth flow

---

## 🔧 Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 📝 Notes

- Supabase URL & Key: Same as PWA project
- Auth methods: email/password (same as existing)

---

## 🧪 Verification (/verify)

1. [ ] `flutter run` works without errors
2. [ ] Login with existing account succeeds
3. [ ] Register new account works
4. [ ] Session persists after app restart
5. [ ] Logout clears session

---

**Next Week:** Week 02 - Data Layer & Kandang CRUD
