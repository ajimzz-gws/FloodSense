import '../models/flood_level.dart';

enum AppLanguage { en, ms }

/// All user-facing text in English and Bahasa Melayu.
///
/// Level names follow the JPS terms: Normal, Waspada, Amaran, Bahaya.
class S {
  const S(this.lang);
  final AppLanguage lang;

  bool get _ms => lang == AppLanguage.ms;
  String _t(String en, String ms) => _ms ? ms : en;

  // Navigation
  String get navHome => _t('Home', 'Utama');
  String get navStations => _t('Stations', 'Stesen');
  String get navMap => _t('Map', 'Peta');
  String get navSettings => _t('Settings', 'Tetapan');

  // Levels
  String levelName(FloodLevel l) => switch (l) {
        FloodLevel.normal => _t('Normal', 'Normal'),
        FloodLevel.alert => _t('Alert', 'Waspada'),
        FloodLevel.warning => _t('Warning', 'Amaran'),
        FloodLevel.danger => _t('Danger', 'Bahaya'),
      };

  String levelAdvice(FloodLevel l) => switch (l) {
        FloodLevel.normal => _t(
            'The river is at a normal level. No action needed.',
            'Paras sungai normal. Tiada tindakan diperlukan.'),
        FloodLevel.alert => _t(
            'The water is rising. Stay alert and follow official updates.',
            'Paras air meningkat. Sentiasa berwaspada dan ikuti makluman rasmi.'),
        FloodLevel.warning => _t(
            'Get ready to leave. Move important documents and valuables to a higher place. Charge your phone.',
            'Bersedia untuk berpindah. Alihkan dokumen penting dan barang berharga ke tempat tinggi. Cas telefon anda.'),
        FloodLevel.danger => _t(
            'Leave now. Go to the nearest relief centre (PPS). Do not walk or drive through flood water. Call 999 in an emergency.',
            'Pindah sekarang. Pergi ke Pusat Pemindahan Sementara (PPS) terdekat. Jangan berjalan atau memandu melalui air banjir. Hubungi 999 jika kecemasan.'),
      };

  // Home
  String get myStation => _t('My station', 'Stesen saya');
  String get waterLevel => _t('Water level', 'Paras air');
  String get whatToDo => _t('What you should do', 'Apa yang perlu dilakukan');
  String get levelsTitle => _t('River levels', 'Paras sungai');
  String get now => _t('NOW', 'KINI');
  String usualLevel(String m) => _t('Usual level $m', 'Paras biasa $m');
  String get updated => _t('Updated', 'Dikemas kini');
  String get sampleData => _t('Sample data', 'Data contoh');
  String get demoValue => _t('Demo value', 'Nilai demo');
  String get changeStation => _t('Change station', 'Tukar stesen');
  String get yourArea => _t('Your area', 'Kawasan anda');
  String get locationOff =>
      _t('Location is off. Turn it on in Settings to get alerts where you are.',
          'Lokasi dimatikan. Hidupkan dalam Tetapan untuk menerima amaran di tempat anda.');
  String get locationWaiting => _t('Finding your location…', 'Mencari lokasi anda…');
  String inZone(String km, String radius) => _t(
      'You are $km km away. You are INSIDE the $radius km alert zone.',
      'Anda $km km dari stesen. Anda BERADA DALAM zon amaran $radius km.');
  String outZone(String km, String radius) => _t(
      'You are $km km away, outside the $radius km alert zone.',
      'Anda $km km dari stesen, di luar zon amaran $radius km.');
  String get pretendingHere => _t(
      'Demo: pretending you are at this station.',
      'Demo: berpura-pura anda berada di stesen ini.');
  String get dataSource =>
      _t('Source: InfoBanjir (JPS Malaysia)', 'Sumber: InfoBanjir (JPS Malaysia)');

  // Weather (MET Malaysia)
  String get weatherTitle => _t('Weather forecast', 'Ramalan cuaca');
  String metSource(String district) =>
      _t('MET Malaysia · $district district', 'MET Malaysia · Daerah $district');
  String get today => _t('Today', 'Hari ini');
  String get morning => _t('Morning', 'Pagi');
  String get afternoon => _t('Afternoon', 'Petang');
  String get night => _t('Night', 'Malam');
  String get nextDays => _t('Next days', 'Hari seterusnya');
  String get showAllDays => _t('Show all 7 days', 'Tunjuk semua 7 hari');
  String get showFewerDays => _t('Show fewer days', 'Tunjuk kurang hari');
  String get weatherLoading => _t('Loading forecast…', 'Memuatkan ramalan…');
  String get weatherFailed => _t(
      'Could not load the forecast. Check your internet connection.',
      'Ramalan tidak dapat dimuatkan. Semak sambungan internet anda.');
  String get retry => _t('Try again', 'Cuba lagi');
  String offlineForecast(String when) => _t(
      'Could not reach MET Malaysia. Showing the forecast saved at $when.',
      'Tidak dapat menghubungi MET Malaysia. Menunjukkan ramalan yang disimpan pada $when.');
  String get rainNoteToday => _t(
      'Heavy rain or thunderstorms expected today. River levels can rise quickly. Keep checking this app.',
      'Hujan lebat atau ribut petir dijangka hari ini. Paras sungai boleh naik dengan cepat. Sentiasa semak aplikasi ini.');
  String get rainNoteSoon => _t(
      'Heavy rain or thunderstorms expected in the next few days. River levels may rise.',
      'Hujan lebat atau ribut petir dijangka beberapa hari lagi. Paras sungai mungkin naik.');
  String forecastText(String metMalay, String Function(String) toEnglish) =>
      _ms ? metMalay : toEnglish(metMalay);
  String weekday(DateTime d) => (_ms
      ? const ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad']
      : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])[d.weekday - 1];
  String shortDate(DateTime d) {
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const ms = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis'];
    return '${d.day} ${(_ms ? ms : en)[d.month - 1]}';
  }

  // Stations
  String get stationsTitle => _t('River stations', 'Stesen sungai');
  String get tapToChoose =>
      _t('Tap a station to make it your station.', 'Tekan stesen untuk jadikan stesen anda.');
  String get selected => _t('Selected', 'Dipilih');
  String get setAsMyStation => _t('Make this my station', 'Jadikan stesen saya');

  // Map
  String get mapTitle => _t('Station map', 'Peta stesen');
  String get you => _t('You', 'Anda');
  String get alertZone => _t('Alert zone', 'Zon amaran');

  // Settings
  String get settingsTitle => _t('Settings', 'Tetapan');
  String get language => _t('Language', 'Bahasa');
  String get textSize => _t('Text size', 'Saiz teks');
  String get sizeNormal => _t('Normal', 'Biasa');
  String get sizeLarge => _t('Large', 'Besar');
  String get sizeXL => _t('Extra large', 'Sangat besar');
  String get textPreview => _t('This is how text will look.', 'Beginilah rupa teks.');
  String get locationTracking => _t('Track my location', 'Jejak lokasi saya');
  String get locationTrackingHint => _t(
      'Keeps checking where you are, even when the app is in the background, so you are warned when you are near a flooding river.',
      'Sentiasa menyemak lokasi anda, walaupun aplikasi di latar belakang, supaya anda diberi amaran apabila berada dekat sungai yang banjir.');
  String get alertMyStation =>
      _t('Always alert me about my station', 'Sentiasa beri amaran tentang stesen saya');
  String get alertMyStationHint => _t(
      'Get alerts for your chosen station even when you are far away (for example, your family\'s area).',
      'Terima amaran untuk stesen pilihan anda walaupun anda jauh (contohnya, kawasan keluarga anda).');
  String get demoMode => _t('Demo mode', 'Mod demo');
  String get demoModeHint => _t(
      'Change water levels by hand to show how alerts work.',
      'Ubah paras air secara manual untuk menunjukkan cara amaran berfungsi.');
  String get permissionDenied => _t(
      'Location permission was refused. Allow it in your phone settings.',
      'Kebenaran lokasi ditolak. Benarkan dalam tetapan telefon anda.');
  String get openSettings => _t('Open phone settings', 'Buka tetapan telefon');

  // Demo
  String get demoTitle => _t('Demo controls', 'Kawalan demo');
  String get demoStation => _t('Station', 'Stesen');
  String get setLevel => _t('Jump to a level', 'Lompat ke paras');
  String get slideLevel => _t('Or slide the water level', 'Atau gelongsor paras air');
  String get playScenario => _t('Play rising flood', 'Main banjir meningkat');
  String get stopScenario => _t('Stop', 'Henti');
  String get playHint => _t(
      'Raises the water step by step from now to Danger. You get an alert at each new level.',
      'Menaikkan air sedikit demi sedikit hingga Bahaya. Anda menerima amaran pada setiap paras baharu.');
  String get pretendHere => _t('Pretend I am at this station', 'Berpura-pura saya di stesen ini');
  String get pretendHereHint => _t(
      'Puts you inside the station\'s alert zone without moving.',
      'Meletakkan anda dalam zon amaran stesen tanpa bergerak.');
  String get resetAll => _t('Reset all to real data', 'Set semula ke data sebenar');
  String get realReading => _t('Real reading', 'Bacaan sebenar');

  // Alert screen
  String alertTitle(FloodLevel l) => switch (l) {
        FloodLevel.danger => _t('FLOOD DANGER', 'BAHAYA BANJIR'),
        FloodLevel.warning => _t('FLOOD WARNING', 'AMARAN BANJIR'),
        _ => _t('FLOOD ALERT', 'WASPADA BANJIR'),
      };
  String alertBody(String station, String level, String metres) => _t(
      '$station is at $level level ($metres m).',
      '$station berada pada paras $level ($metres m).');
  String get understood => _t('I understand', 'Saya faham');
  String get trackingNotifTitle => _t('FloodSense is on', 'FloodSense aktif');
  String get trackingNotifBody => _t(
      'Watching for floods near you', 'Memantau banjir berhampiran anda');
}
