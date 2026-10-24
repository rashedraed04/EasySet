import 'package:flutter/material.dart';

final ValueNotifier<String> languageNotifier = ValueNotifier('en');

String translate(String key) {
  if (languageNotifier.value == 'en') return key;
  return _arabicMap[key] ?? key;
}

const Map<String, String> _arabicMap = {
  // Navigation
  'Workouts': 'التدريبات',
  'Routines': 'الروتينات',
  'Graph': 'الرسم البياني',
  'Settings': 'الإعدادات',

  // Settings
  'Account': 'الحساب',
  'Appearance': 'المظهر',
  'Light Mode': 'الوضع الفاتح',
  'Language': 'اللغة',
  'English': 'الإنجليزية',
  'Arabic': 'العربية',
  'Training': 'التمرين',
  'Default rest time': 'وقت الراحة الافتراضي',
  'Made by Rashed Al-Awamleh': 'تم الإنشاء بواسطة راشد العواملة',

  // Cloud backup
  'Cloud backup': 'النسخ الاحتياطي السحابي',
  'Cloud backup is not set up in this build.': 'النسخ الاحتياطي السحابي غير مفعّل في هذا الإصدار.',
  'Back up your workouts': 'احفظ تمارينك',
  'Sign in to keep your data safe and restore it on any device.':
      'سجّل الدخول لحفظ بياناتك واستعادتها على أي جهاز.',
  'Sign in with Google': 'تسجيل الدخول بحساب جوجل',
  'Sign-in failed': 'فشل تسجيل الدخول',
  'Backed up': 'تم النسخ الاحتياطي',
  'Syncing…': 'جارٍ المزامنة…',
  'Sync failed': 'فشلت المزامنة',
  'Retry': 'إعادة المحاولة',
  'Sign out': 'تسجيل الخروج',

  // Logging
  'Log Exercise': 'تسجيل تمرين',
  'Exercise Name': 'اسم التمرين',
  'Weight (kg)': 'الوزن (كجم)',
  'Date': 'التاريخ',
  'Sets': 'المجموعات',
  'Reps': 'التكرارات',
  'Save': 'حفظ',
  'Add New Exercise': 'إضافة تمرين جديد',
  'Add': 'إضافة',
  'Cancel': 'إلغاء',
  'Delete': 'حذف',
  'Remove': 'إزالة',
  'Remove from list': 'إزالة من القائمة',
  'Remove this exercise from the list?': 'هل تريد إزالة هذا التمرين من القائمة؟',
  'Logged sessions are kept.': 'الجلسات المسجلة ستبقى كما هي.',
  'Choose an exercise': 'اختر تمرينًا',
  'Enter a valid weight': 'أدخل وزنًا صحيحًا',
  'No exercises logged yet.': 'لم يتم تسجيل أي تمارين بعد.',
  'sessions': 'جلسات',
  'Delete Exercise': 'حذف التمرين',
  'Are you sure you want to delete this session of': 'هل أنت متأكد من حذف هذه الجلسة من',
  'Are you sure you want to delete all sessions of': 'هل أنت متأكد من حذف جميع جلسات',

  // Graph
  'Weight': 'الوزن',
  'Est. 1RM': 'أقصى وزن تقديري',

  // Records
  'PR': 'رقم قياسي',
  'New PR!': 'رقم قياسي جديد!',
  'New PRs': 'أرقام قياسية جديدة',

  // Rest timer
  'Rest Timer': 'مؤقت الراحة',
  'Start default rest': 'ابدأ الراحة الافتراضية',
  'Rest over - go!': 'انتهت الراحة - هيا!',
  'Dismiss': 'إغلاق',

  // Routines
  'No routines yet. Tap + to create one.': 'لا توجد روتينات بعد. اضغط + لإنشاء واحد.',
  'Start Workout': 'ابدأ التمرين',
  'New Routine': 'روتين جديد',
  'Edit Routine': 'تعديل الروتين',
  'Routine Name': 'اسم الروتين',
  'e.g. Push Day': 'مثال: يوم الدفع',
  'Add Exercise': 'إضافة تمرين',
  'Give the routine a name': 'أعطِ الروتين اسمًا',
  'Add at least one exercise': 'أضف تمرينًا واحدًا على الأقل',
  'Delete Routine': 'حذف الروتين',
  'Are you sure you want to delete the routine': 'هل أنت متأكد من حذف الروتين',

  // Workout session
  'Finish': 'إنهاء',
  'Log': 'تسجيل',
  'Update': 'تحديث',
  'Last': 'آخر مرة',
  'First time - pick a starting weight': 'أول مرة - اختر وزن البداية',
  'Workout complete': 'اكتمل التمرين',
  'Duration': 'المدة',
  'min': 'د',
  'Exercises': 'التمارين',
  'Total volume': 'إجمالي الحجم',
  'Done': 'تم',

  // Default exercises
  'Bench Press': 'ضغط الصدر',
  'Squat': 'القرفصاء',
  'Deadlift': 'الرفعة الميتة',
  'Overhead Press': 'الضغط فوق الرأس',
};
