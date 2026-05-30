import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/services/battery_service.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/contact_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/openai_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/stt_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/services/usb_service.dart';

class HomeViewModel extends ChangeNotifier {
  final TtsService _ttsService = TtsService();
  final SttService _sttService = SttService();
  final PermissionService _permissionService = PermissionService();
  final BatteryService _batteryService = BatteryService();
  final CameraService _cameraService = CameraService();
  final OpenAIService _openAIService = OpenAIService();
  final UsbService _usbService = UsbService();
  final PdfService _pdfService = PdfService();
  final ContactService _contactService = ContactService();
  final LocationService _locationService = LocationService();

  static const platform = MethodChannel('com.example.whatsapp'); // For endCall

  CameraDescription? camera;

  // State variables
  String usbStatus = "Terputus";
  String receivedData = "Tidak ada data diterima";
  String imageDescription = "Tidak ada deskripsi gambar";
  String speechResult = "Tidak ada hasil perintah suara";
  String lastSpokenText = "";
  String lastMatchedContact = "";

  bool isListening = false;
  bool isCapturingImages = false;
  bool hasCapturedImage = false;
  bool isSelectingMode = false;
  bool isConfirmingContact = false;
  bool isClarifyingContact = false;
  bool isConfirmingShareLocation = false;

  String? selectedMode;
  String callType = 'direct';

  String? pendingContactName;
  String? pendingContactPhone;
  String? pendingImageDescription;
  String? pendingShareContactName;
  String? pendingShareContactPhone;
  String? pendingLocationMessage;
  List<MapEntry<String, double>> ambiguousMatches = [];

  // Getters
  List<dynamic> get contacts => _contactService.contacts;

  HomeViewModel({required this.camera}) {
    _init();
  }

  Future<void> _init() async {
    await _ttsService.init();
    await _sttService.init();
    await _permissionService.requestAllPermissions();

    if (camera != null) {
      await _cameraService.initialize(camera!);
    }

    try {
      await _contactService.loadContacts();
    } catch (e) {
      print("Error loading contacts: $e");
      await _ttsService.speak("Gagal memuat kontak. Pastikan izin diberikan.");
    }

    _usbService.init(
      onData: (data) => _handleUsbData(data),
      onStatus: (status) {
        usbStatus = status;
        notifyListeners();
      },
    );

    _batteryService.onBatteryStateChanged.listen((state) {
      _checkBattery();
    });
    _checkBattery();

    await _ttsService.speak(
      "Asisten Tunanetra aktif. Gunakan tombol UI atau USB: Tombol 1 atau N_1 untuk membatalkan, Tombol 2 atau N_2 untuk mengonfirmasi panggilan, Tombol 3 atau N_3 untuk mengakhiri panggilan atau membatalkan pemilihan mode, Tombol 4 atau N_4 untuk memilih mode dan mengambil gambar, Tombol 5 atau N_5 untuk menyimpan deskripsi gambar atau membatalkan lokasi, Tombol 6 atau N_6 untuk membaca PDF, Tombol 7 atau N_7 untuk membagikan lokasi.",
    );
  }

  Future<void> _checkBattery() async {
    bool isLow = await _batteryService.isBatteryLow();
    if (isLow) {
      WakelockPlus.disable();
    } else {
      WakelockPlus.enable();
    }
  }

  void _handleUsbData(String data) {
    receivedData = data;
    notifyListeners();
    print("USB Data: $data");

    switch (data) {
      case "N_1":
        _handleN1();
        break;
      case "N_2":
        _handleN2();
        break;
      case "N_3":
        _handleN3();
        break;
      case "N_4":
        _handleN4();
        break;
      case "N_5":
        _handleN5();
        break;
      case "N_6":
        handleN6();
        break;
      case "N_7":
        handleN7();
        break;
    }
  }

  Future<void> _handleN1() async {
    if (isConfirmingContact || isClarifyingContact) {
      isConfirmingContact = false;
      isClarifyingContact = false;
      ambiguousMatches = [];
      pendingContactName = null;
      pendingContactPhone = null;
      speechResult = "Konfirmasi kontak dibatalkan";
      lastSpokenText = "";
      lastMatchedContact = "";
      notifyListeners();
      await _ttsService.speak(
          "Konfirmasi kontak dibatalkan, sebutkan nama yang ingin anda hubungi");
      startListening();
    } else if (isCapturingImages || pendingImageDescription != null) {
      isCapturingImages = false;
      pendingImageDescription = null;
      imageDescription = "Konfirmasi gambar dibatalkan";
      selectedMode = null;
      isSelectingMode = false;
      notifyListeners();
      await _ttsService.speak(
          "Konfirmasi gambar dibatalkan. Tekan tombol 4 untuk memilih mode dan mengambil gambar lagi.");
    } else {
      await _ttsService.speak("Sebutkan nama yang ingin anda hubungi");
      startListening();
    }
  }

  Future<void> _handleN2() async {
    if (isConfirmingContact &&
        pendingContactName != null &&
        pendingContactPhone != null) {
      await launchCall(pendingContactName!, pendingContactPhone!);
      isConfirmingContact = false;
      pendingContactName = null;
      pendingContactPhone = null;
      notifyListeners();
    } else {
      await _ttsService
          .speak("Tidak ada aksi yang menunggu konfirmasi untuk tombol 2");
    }
  }

  Future<void> _handleN3() async {
    if (isSelectingMode) {
      isSelectingMode = false;
      selectedMode = null;
      speechResult = "Pemilihan mode dibatalkan";
      notifyListeners();
      await _ttsService.speak("Pemilihan mode dibatalkan");
    } else {
      try {
        await platform.invokeMethod('endCall');
        await _ttsService.speak("Panggilan telah diakhiri");
      } catch (e) {
        print("Error ending call: $e");
        await _ttsService.speak("Gagal mengakhiri panggilan");
      }
    }
  }

  Future<void> _handleN4() async {
    await WakelockPlus.enable();
    await _ttsService.speak("Layar dihidupkan kembali");

    if (!isSelectingMode && selectedMode == null) {
      isSelectingMode = true;
      notifyListeners();

      await _ttsService.speak("Pilih mode: Deskripsi Visual atau Scan Dokumen");
      String? result = await _sttService.listen();

      if (result != null) {
        String resultLower = result.toLowerCase();
        if (resultLower.contains("deskripsi") ||
            resultLower.contains("visual")) {
          selectedMode = "visual";
        } else if (resultLower.contains("scan") ||
            resultLower.contains("dokumen")) {
          selectedMode = "scan";
        }

        if (selectedMode != null) {
          speechResult =
              "Mode dipilih: ${selectedMode == 'visual' ? 'Deskripsi Visual' : 'Scan Dokumen'}";
          notifyListeners();
          await _ttsService.speak(
              "Mode ${selectedMode == 'visual' ? 'Deskripsi Visual' : 'Scan Dokumen'} dipilih. Tekan tombol 4 lagi untuk mengambil gambar.");
        } else {
          isSelectingMode = false;
          notifyListeners();
          await _ttsService.speak("Maaf, anda belum memilih mode");
        }
      } else {
        isSelectingMode = false;
        notifyListeners();
        await _ttsService.speak("Kesalahan saat memilih mode");
      }
    } else if (selectedMode != null) {
      if (!isCapturingImages) {
        isSelectingMode = false;
        notifyListeners();
        await _ttsService.speak("Mengambil dan memproses gambar satu kali.");
        captureImage();
      }
    } else {
      await _ttsService.speak("Silakan pilih mode terlebih dahulu");
    }
  }

  Future<void> _handleN5() async {
    if (isConfirmingShareLocation) {
      isConfirmingShareLocation = false;
      pendingShareContactName = null;
      pendingShareContactPhone = null;
      pendingLocationMessage = null;
      receivedData = "Pengiriman lokasi dibatalkan";
      notifyListeners();
      await _ttsService.speak("Pengiriman lokasi dibatalkan");
    } else if (pendingImageDescription != null) {
      // Save PDF logic
      String? fileName;
      await _ttsService.speak("Sebutkan nama file untuk PDF");
      String? spokenName = await _sttService.listen();

      if (spokenName != null && spokenName.isNotEmpty) {
        fileName = spokenName
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(' ', '_')
            .toLowerCase();
        if (!fileName.endsWith('.pdf')) fileName += '.pdf';
      } else {
        fileName =
            'image_description_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await _ttsService
            .speak("Nama file tidak terdeteksi, menggunakan nama default");
      }

      await _pdfService.savePdf(fileName, pendingImageDescription!);
      await _ttsService.speak(
          "Deskripsi disimpan sebagai PDF dengan nama $fileName. Tekan tombol 4 untuk memilih mode dan mengambil gambar lagi.");

      isCapturingImages = false;
      pendingImageDescription = null;
      selectedMode = null;
      isSelectingMode = false;
      notifyListeners();
    } else {
      // Reset capture if needed
      isCapturingImages = false;
      pendingImageDescription = null;
      imageDescription = "Pengambilan gambar dimatikan";
      selectedMode = null;
      isSelectingMode = false;
      notifyListeners();
      await _ttsService.speak(
          "Pengambilan gambar dimatikan. Tekan tombol 4 untuk memilih mode dan mulai lagi.");
    }
  }

  Future<void> handleN6() async {
    await _ttsService.speak("Sebutkan nama file PDF untuk dibaca");
    String? fileName = await _sttService.listen();

    if (fileName != null && fileName.isNotEmpty) {
      fileName = fileName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_')
          .toLowerCase();
      if (!fileName.endsWith('.pdf')) fileName += '.pdf';
    } else {
      // Default logic or cancel
      await _ttsService.speak("Nama file tidak terdeteksi");
      return;
    }

    await _ttsService.speak("Mencari file PDF dengan nama $fileName");
    try {
      String? text = await _pdfService.extractTextFromPdf(fileName);
      if (text != null && text.isNotEmpty) {
        await _ttsService.speak(text);
      } else {
        await _ttsService.speak("PDF tidak ditemukan atau kosong");
      }
    } catch (e) {
      await _ttsService.speak("Gagal membaca PDF");
    }
  }

  Future<void> handleN7() async {
    if (isConfirmingShareLocation &&
        pendingShareContactName != null &&
        pendingLocationMessage != null) {
      // Confirm send
      String formattedNumber = formatPhone(pendingShareContactPhone!);
      try {
        await sendSMS(
            message: pendingLocationMessage!,
            recipients: [formattedNumber],
            sendDirect: true);
        receivedData = "Lokasi dikirim ke $pendingShareContactName";
        notifyListeners();
        await _ttsService
            .speak("Lokasi telah dikirim ke $pendingShareContactName via SMS");
      } catch (e) {
        await _ttsService.speak("Gagal mengirim lokasi");
      }
      isConfirmingShareLocation = false;
      pendingShareContactName = null;
      pendingShareContactPhone = null;
      pendingLocationMessage = null;
      notifyListeners();
    } else {
      // Start share location process
      if (!await _locationService.isLocationServiceEnabled()) {
        await _ttsService.speak("Layanan lokasi tidak diaktifkan");
        return;
      }

      await _ttsService.speak("Mengambil lokasi saat ini");
      try {
        String locationUrl = await _locationService.getCurrentLocationUrl();
        String readable = await _locationService.getCurrentLocationReadable();
        await _ttsService.speak("Lokasi saat ini: $readable");

        pendingLocationMessage = "Lokasi saya: $locationUrl";
        notifyListeners();

        await _ttsService.speak("Sebutkan nama kontak untuk mengirim lokasi");
        String? contactName = await _sttService.listen();

        if (contactName == null || contactName.isEmpty) {
          await _ttsService.speak("Nama kontak tidak terdeteksi");
          return;
        }

        var matches = _contactService.getTopMatches(contactName);
        if (matches.isNotEmpty) {
          var bestMatch = matches.first;
          var matchedContact =
              contacts.firstWhere((c) => c.displayName == bestMatch.key);
          if (matchedContact.phones.isEmpty) {
            await _ttsService.speak("Kontak tidak memiliki nomor telepon");
            return;
          }

          isConfirmingShareLocation = true;
          pendingShareContactName = matchedContact.displayName;
          pendingShareContactPhone = matchedContact.phones.first.number;
          notifyListeners();

          await _ttsService.speak(
              "Apakah Anda maksud mengirim lokasi ke ${matchedContact.displayName}? Tekan tombol 7 untuk mengonfirmasi, atau tombol 5 untuk membatalkan.");
        } else {
          await _ttsService.speak("Kontak tidak ditemukan");
        }
      } catch (e) {
        print("Error location: $e");
        await _ttsService.speak("Gagal mendapatkan lokasi");
      }
    }
  }

  Future<void> startListening() async {
    isListening = true;
    notifyListeners();
    String? result = await _sttService.listen();

    if (result != null) {
      speechResult = result;
      notifyListeners();
      String lowerResult = result.toLowerCase();

      if (lowerResult.contains("telepon") || lowerResult.contains("hubungi")) {
        // Simply use the whole text since extract logic was a bit specific
        // Or try to use the same logic if I can port it.
        // For now, let's just assume the name is in the text.
        // A better way is to pass the text to a helper that strips keywords.
        String name = _extractName(lowerResult);

        var matches = _contactService.getTopMatches(name);
        if (matches.isNotEmpty) {
          // Detection of ambiguity: multiple matches with score > 80 and difference < 15
          if (matches.length > 1 &&
              matches[0].value > 80 &&
              (matches[0].value - matches[1].value) < 15) {
            isClarifyingContact = true;
            ambiguousMatches = matches.take(3).toList(); // max 3 to be clear
            notifyListeners();

            String names = ambiguousMatches.map((e) => e.key).join(", dan ");
            await _ttsService.speak(
                "Saya menemukan ${ambiguousMatches.length} nama yang mirip: $names. Yang mana yang Anda maksud?");

            // Listen specifically for the choice
            String? choice = await _sttService.listen();
            if (choice != null) {
              // Narrow down again
              var subMatches = _contactService.getTopMatches(choice);
              if (subMatches.isNotEmpty) {
                // If it's still ambiguous, we pick the best from the sub-matches
                // but usually the user will speak the specific name now.
                var bestChoice = subMatches.first;
                var matchedContact =
                    contacts.firstWhere((c) => c.displayName == bestChoice.key);

                isClarifyingContact = false;
                ambiguousMatches = [];
                isConfirmingContact = true;
                pendingContactName = matchedContact.displayName;
                pendingContactPhone = matchedContact.phones.first.number;

                lastSpokenText = choice;
                lastMatchedContact =
                    "${matchedContact.displayName} (${matchedContact.phones.first.number})";
                speechResult =
                    "Mic (Klarifikasi): $choice\nCocok: $lastMatchedContact (Skor: ${bestChoice.value.toStringAsFixed(0)}%)";
                notifyListeners();

                await _ttsService.speak(
                    "Apakah Anda maksud menelpon ${matchedContact.displayName}? Tekan tombol 2 untuk mengonfirmasi.");
                return;
              }
            }
            // fallback if choice not detected or ambiguous again
            isClarifyingContact = false;
            ambiguousMatches = [];
            notifyListeners();
            await _ttsService
                .speak("Pilihan tidak jelas, silakan ulangi perintah hubungi");
            return;
          }

          var bestMatch = matches.first;
          var matchedContact =
              contacts.firstWhere((c) => c.displayName == bestMatch.key);
          if (matchedContact.phones.isEmpty) {
            await _ttsService.speak(
                "Kontak ${matchedContact.displayName} tidak memiliki nomor telepon");
            isListening = false;
            notifyListeners();
            return;
          }

          isConfirmingContact = true;
          pendingContactName = matchedContact.displayName;
          pendingContactPhone = matchedContact.phones.first.number;

          double score = bestMatch.value;
          lastSpokenText = lowerResult;
          lastMatchedContact =
              "${matchedContact.displayName} (${matchedContact.phones.first.number})";
          speechResult =
              "Mic: $lowerResult\nCocok: $lastMatchedContact (Skor: ${score.toStringAsFixed(0)}%)";

          notifyListeners();
          await _ttsService.speak(
              "Apakah Anda maksud menelpon ${matchedContact.displayName}? Tekan tombol 2 untuk mengonfirmasi.");
        } else {
          lastSpokenText = lowerResult;
          lastMatchedContact = "Tidak ditemukan";
          speechResult = "Mic: $lowerResult\nCocok: Tidak ditemukan";
          notifyListeners();
          await _ttsService.speak("Kontak tidak ditemukan, coba ucapkan lagi");
        }
      } else if (lowerResult.contains("kirim pesan") ||
          lowerResult.contains("sms")) {
        // SMS logic similar to above
        await _ttsService.speak("Sebutkan nama kontak untuk mengirim pesan");
        String? name = await _sttService.listen();
        if (name != null) {
          var matches = _contactService.getTopMatches(name);
          if (matches.isNotEmpty) {
            // Found contact, now ask for message
            var matchedContact =
                contacts.firstWhere((c) => c.displayName == matches.first.key);
            String phone = matchedContact.phones.first.number;

            await _ttsService.speak("Sebutkan pesan yang ingin dikirim");
            String? message = await _sttService.listen();
            if (message != null) {
              await sendSMS(
                  message: message,
                  recipients: [formatPhone(phone)],
                  sendDirect: true);
              await _ttsService.speak("Pesan dikirim");
            } else {
              await _ttsService.speak("Pesan tidak terdeteksi");
            }
          } else {
            await _ttsService.speak("Kontak tidak ditemukan");
          }
        }
      } else {
        await _ttsService.speak("Perintah tidak dikenali");
      }
    }

    isListening = false;
    notifyListeners();
  }

  String _extractName(String text) {
    // Simple extraction
    List<String> keywords = [
      "hubungi",
      "telepon",
      "panggil",
      "kontak",
      "pesan",
      "kirim",
      "sms",
      "ke",
      "saya",
      "nama"
    ];
    String cleaned = text;
    for (var word in keywords) {
      cleaned = cleaned.replaceAll(word, "");
    }
    return cleaned.trim();
  }

  Future<void> captureImage() async {
    isCapturingImages = true;
    notifyListeners();
    await _ttsService.speak("Mengambil gambar sekarang...");

    String? base64Image = await _cameraService.takePictureBase64();
    if (base64Image != null) {
      await _ttsService.speak("Memproses gambar...");
      imageDescription = "Mendapatkan deskripsi gambar...";
      hasCapturedImage = true;
      notifyListeners();

      String? description =
          await _openAIService.describeImage(base64Image, mode: selectedMode!);
      imageDescription = description ?? "Gagal mendapatkan deskripsi";
      pendingImageDescription = description;
      notifyListeners();
      await _ttsService.speak(
          "Mode ${selectedMode == 'visual' ? 'Deskripsi Visual' : 'Scan Dokumen'} ON. $imageDescription. Tekan tombol 5 untuk menyimpan deskripsi, atau tombol 1 untuk membatalkan.");
    } else {
      await _ttsService.speak("Gagal mengambil gambar");
    }

    isCapturingImages = false;
    selectedMode = null; // Reset?
    isSelectingMode = false;
    notifyListeners();
  }

  Future<void> launchCall(String name, String phone) async {
    await _ttsService.speak("Memulai panggilan ke $name");
    bool? res = await FlutterPhoneDirectCaller.callNumber(formatPhone(phone));
    if (res != true) await _ttsService.speak("Gagal memulai panggilan");
  }

  String formatPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('0')) {
      return '+62${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      return '+62$cleaned';
    }
    return cleaned;
  }

  @override
  void dispose() {
    _batteryService.dispose();
    _cameraService.dispose();
    _usbService.dispose();
    _ttsService.stop();
    _sttService.stop();
    super.dispose();
  }

  // Helper to trigger N inputs from UI for testing/accessibility
  void triggerN(String n) => _handleUsbData(n);

  void speak(String text) => _ttsService.speak(text);
  void speakContact(String name) => _ttsService.speak("Kontak: $name");
}
