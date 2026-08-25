import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'assessment_engine.dart';
import '../models/game_assessment.dart';
import '../models/test_result.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AIReportService
//
//  Service untuk mengirim data asesmen ke API AI dan mendapatkan laporan
//  perkembangan anak yang dipersonalisasi dalam Bahasa Indonesia.
//
//  Mendukung 3 provider:
//    - Google Gemini (direkomendasikan, lebih murah)
//    - OpenAI GPT-4
//    - Mock mode (untuk development & testing tanpa API)
//
//  Penggunaan:
//    final service = AIReportService();
//    final report = await service.generateReport(
//      childName: 'Rian', childAge: 7, ...
//    );
// ═══════════════════════════════════════════════════════════════════════════

/// Status proses pembuatan laporan AI.
enum AIReportStatus { idle, loading, success, error }

/// Hasil laporan AI yang dihasilkan untuk satu anak.
class AIReport {
  final String rawMarkdown;      // Teks laporan dalam format Markdown
  final DateTime generatedAt;
  final String provider;         // 'gemini' | 'openai' | 'mock'
  final Map<String, dynamic> assessmentPayload; // JSON asli yang dikirim ke AI
  final bool fromCache;

  const AIReport({
    required this.rawMarkdown,
    required this.generatedAt,
    required this.provider,
    required this.assessmentPayload,
    this.fromCache = false,
  });

  Map<String, dynamic> toJson() => {
    'rawMarkdown': rawMarkdown,
    'generatedAt': generatedAt.toIso8601String(),
    'provider': provider,
    'assessmentPayload': assessmentPayload,
    'fromCache': fromCache,
  };

  factory AIReport.fromJson(Map<String, dynamic> json) {
    return AIReport(
      rawMarkdown: json['rawMarkdown'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
      provider: json['provider'] as String? ?? 'gemini',
      assessmentPayload: json['assessmentPayload'] as Map<String, dynamic>? ?? {},
      fromCache: json['fromCache'] as bool? ?? false,
    );
  }
}

class AIReportService {
  // Singleton
  static final AIReportService _instance = AIReportService._internal();
  factory AIReportService() => _instance;
  AIReportService._internal();

  // Cache laporan terakhir (dalam memori, tidak persisten)
  AIReport? _cachedReport;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  // ──────────────────────────────────────────────────────────────────────────
  //  MAIN PUBLIC METHOD
  // ──────────────────────────────────────────────────────────────────────────

  /// Menghasilkan laporan perkembangan anak dari data asesmen.
  ///
  /// [apiKey]     — API key untuk provider yang dipilih. Kosongkan untuk mock mode.
  /// [provider]   — 'gemini', 'openai', atau 'mock'
  /// [forceRefresh] — paksa regenerasi meski ada cache
  Future<AIReport> generateReport({
    required String childName,
    required int childAge,
    required String childGender,
    required AllGameAssessments games,
    required TestResults testResults,
    String apiKey = '',
    String provider = 'mock',
    bool forceRefresh = false,
  }) async {
    // Return cache jika masih valid dan tidak dipaksa refresh
    if (!forceRefresh && _cachedReport != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheDuration) {
        return AIReport(
          rawMarkdown: _cachedReport!.rawMarkdown,
          generatedAt: _cachedReport!.generatedAt,
          provider: _cachedReport!.provider,
          assessmentPayload: _cachedReport!.assessmentPayload,
          fromCache: true,
        );
      }
    }

    // Build payload JSON untuk AI
    final payload = AssessmentEngine.buildAIPayload(
      childName: childName,
      childAge: childAge,
      childGender: childGender,
      games: games,
      testResults: testResults,
    );

    debugPrint('[AIReportService] Provider: $provider | Payload keys: ${payload.keys.join(', ')}');

    String reportMarkdown;

    try {
      switch (provider.toLowerCase()) {
        case 'gemini':
          reportMarkdown = await _callGemini(apiKey, payload, childName, childAge, childGender, testResults);
          break;
        case 'openai':
          reportMarkdown = await _callOpenAI(apiKey, payload, childName, childAge, childGender, testResults);
          break;
        case 'mock':
        default:
          reportMarkdown = _generateMockReport(payload, childName, childAge, testResults);
          break;
      }
    } catch (e) {
      debugPrint('[AIReportService] Error: $e — falling back to mock report');
      reportMarkdown = _generateMockReport(payload, childName, childAge, testResults);
      provider = 'mock (fallback)';
    }

    final report = AIReport(
      rawMarkdown: reportMarkdown.replaceAll('**', ''),
      generatedAt: DateTime.now(),
      provider: provider,
      assessmentPayload: payload,
    );

    _cachedReport = report;
    _cacheTime = DateTime.now();

    return report;
  }

  void clearCache() {
    _cachedReport = null;
    _cacheTime = null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PROVIDER: GOOGLE GEMINI
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _callGemini(
    String apiKey,
    Map<String, dynamic> payload,
    String childName,
    int childAge,
    String childGender,
    TestResults testResults,
  ) async {
    const model = 'gemini-3.5-flash'; // Lebih murah dari Pro, cukup untuk laporan teks
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final systemPrompt = AssessmentEngine.buildSystemPrompt();
    final userMessage = AssessmentEngine.buildUserMessage(payload);

    final requestBody = {
      'system_instruction': {
        'parts': [{'text': systemPrompt}],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': userMessage}],
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1500,
        'responseMimeType': 'text/plain',
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
      ],
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text != null && text.isNotEmpty) return text;
      throw Exception('Gemini returned empty response');
    } else {
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PROVIDER: OPENAI GPT-4
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _callOpenAI(
    String apiKey,
    Map<String, dynamic> payload,
    String childName,
    int childAge,
    String childGender,
    TestResults testResults,
  ) async {
    const url = 'https://api.openai.com/v1/chat/completions';

    final systemPrompt = AssessmentEngine.buildSystemPrompt();
    final userMessage = AssessmentEngine.buildUserMessage(payload);

    final requestBody = {
      'model': 'gpt-4o-mini', // Lebih murah dari gpt-4o, cukup untuk laporan
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.7,
      'max_tokens': 1500,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text = data['choices']?[0]?['message']?['content'] as String?;
      if (text != null && text.isNotEmpty) return text;
      throw Exception('OpenAI returned empty response');
    } else {
      throw Exception('OpenAI API error ${response.statusCode}: ${response.body}');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PROVIDER: MOCK (Development Mode)
  // ──────────────────────────────────────────────────────────────────────────

  /// Menghasilkan laporan dummy untuk development tanpa API key.
  /// Sudah dipersonalisasi dengan data anak yang sebenarnya.
  String _generateMockReport(
    Map<String, dynamic> payload,
    String childName,
    int childAge,
    TestResults testResults,
  ) {
    final cognitiveProfile = payload['cognitiveProfile'] as Map<String, dynamic>;
    final linguisticProfile = payload['linguisticProfile'] as Map<String, dynamic>;
    final socialProfile = payload['socialEmotionalProfile'] as Map<String, dynamic>;
    final motorProfile = payload['motorProfile'] as Map<String, dynamic>;
    final crossDomain = payload['crossDomainAnalysis'] as Map<String, dynamic>;

    final cogScore = cognitiveProfile['compositeScore'] as num? ?? 0;
    final linScore = linguisticProfile['compositeScore'] as num? ?? 0;
    final socScore = socialProfile['compositeScore'] as num? ?? 0;
    final motScore = motorProfile['compositeScore'] as num? ?? 0;

    final cogClassif = cognitiveProfile['classification'] as String? ?? 'Cukup';
    final socClassif = AssessmentEngine.getPerformanceClassification(socScore.toDouble());
    final motClassif = AssessmentEngine.getPerformanceClassification(motScore.toDouble());
    final strongest = crossDomain['strongestDomain'] as String? ?? 'Kognitif';
    final completedDomains = (crossDomain['completedDomains'] as List?)?.join(', ') ?? 'Belum ada';
    final needsProfEval = crossDomain['recommendProfessionalEvaluation'] as bool? ?? false;

    // Tentukan kekuatan utama untuk rekomendasi
    final strengthAdvice = _getStrengthAdvice(strongest);
    final cogInterpret = AssessmentEngine.getDomainInterpretation('Kognitif', cogScore.toDouble());
    final linInterpret = AssessmentEngine.getDomainInterpretation('Linguistik', linScore.toDouble());
    final socInterpret = AssessmentEngine.getDomainInterpretation('Kepribadian', socScore.toDouble());
    final motInterpret = AssessmentEngine.getDomainInterpretation('Motorik', motScore.toDouble());

    return '''## 🌟 Halo, Mama/Papa $childName!

Terima kasih sudah memberikan waktu bermain yang menyenangkan untuk ${childName}! Kami telah menganalisis perjalanan bermainnya dan punya kabar baik untuk dibagikan. 😊

---

## 📊 Ringkasan Profil ${childName} (${childAge} tahun)

$childName menunjukkan **semangat belajar yang tinggi** dan **keterlibatan yang aktif** sepanjang sesi permainan. Berdasarkan data dari ${completedDomains}, $childName sedang berada pada jalur perkembangan yang sangat positif! Domain terkuatnya adalah **${strongest}**, yang menunjukkan potensi luar biasa di area tersebut.

---

## 💪 Kekuatan Utama ${childName}

**1. ${strongest} — Potensi Unggulan** 🏆
$strengthAdvice

**2. Semangat & Keterlibatan Bermain** 🎮
${childName} menunjukkan keterlibatan yang konsisten dalam setiap sesi permainan. Ini adalah indikator positif tentang motivasi intrinsik dan rasa ingin tahu yang sehat untuk usianya.

**3. Kemampuan Kognitif** 🧠
Dengan skor kognitif **${cogScore}/100 (${cogClassif})**, ${cogInterpret['conclusion']}

---

## 🌱 Area yang Bisa Dikembangkan

**1. Kemampuan Linguistik (Skor: $linScore/100)**
${linInterpret['conclusion']}
→ *${linInterpret['suggestion']}*

**2. Sosial-Emosional (Skor: $socScore/100 — $socClassif)**
${socInterpret['conclusion']}
→ *${socInterpret['suggestion']}*

**3. Motorik (Skor: $motScore/100 — $motClassif)**
${motInterpret['conclusion']}
→ *${motInterpret['suggestion']}*

---

## 🏠 Aktivitas di Rumah yang Bisa Dilakukan

1. 📖 **Membaca bersama** — 15 menit sebelum tidur, bacakan cerita menarik dan diskusikan karakternya
2. 🧩 **Puzzle & teka-teki** — mulai dari yang sederhana, tingkatkan tingkat kesulitan bertahap
3. 🎨 **Menggambar sambil bercerita** — ajak $childName bercerita tentang gambar yang dibuatnya
4. 🔢 **Permainan angka sederhana** — hitung benda-benda di rumah bersama-sama
5. 🌳 **Eksplorasi alam** — amati lingkungan sekitar untuk merangsang rasa ingin tahu

---

## 🎯 Target 1-2 Bulan ke Depan

Dalam **1-2 bulan ke depan**, dengan stimulasi yang konsisten, $childName bisa:
- Meningkatkan skor keseluruhan sebesar **10-15 poin**
- Memperluas kosakata dengan **20-30 kata baru**
- Menyelesaikan lebih banyak level di game yang menantang

---

${needsProfEval ? '''## ⚠️ Catatan Penting
Beberapa area menunjukkan skor di bawah rata-rata. Hal ini normal dan bisa terjadi karena banyak faktor (hari yang lelah, konsentrasi kurang, dll). Namun bila kondisi ini berulang setelah beberapa sesi, kami menyarankan untuk berkonsultasi dengan psikolog anak atau konsultan tumbuh kembang untuk mendapatkan panduan yang lebih personal.

---

''' : ''}## ❤️ Pesan untuk Papa & Mama

Setiap anak berkembang dengan caranya yang unik dan istimewa. Yang paling penting adalah cinta, dukungan, dan waktu berkualitas yang kalian berikan setiap hari. $childName beruntung memiliki orang tua yang peduli seperti kalian! 

**Teruskan permainan! Setiap sesi adalah investasi untuk masa depan ${childName}.** 🌟

---
*Laporan ini dihasilkan berdasarkan data bermain di aplikasi Zikola. Ini adalah panduan awal, bukan diagnosis klinis. Untuk evaluasi komprehensif, konsultasikan dengan profesional.*''';
  }

  String _getStrengthAdvice(String domain) {
    switch (domain) {
      case 'Kognitif':
        return '$domain yang kuat menunjukkan kemampuan logika, penalaran, dan pemecahan masalah yang sangat baik. Anak dengan kekuatan kognitif tinggi sering unggul dalam matematika dan ilmu sains.';
      case 'Linguistik':
        return '$domain yang berkembang baik menunjukkan kemampuan bahasa, kosakata, dan komunikasi yang menonjol. Ini adalah fondasi penting untuk kemampuan membaca dan menulis.';
      case 'Kepribadian':
        return 'Profil sosial-emosional yang positif menunjukkan kemampuan bersosialisasi dan regulasi emosi yang baik. Ini adalah kunci kesuksesan dalam hubungan sosial dan kehidupan sehari-hari.';
      case 'Motorik':
        return 'Kemampuan motorik yang baik menunjukkan koordinasi tubuh dan ketangkasan yang menonjol. Ini mendukung pembelajaran berbagai keterampilan fisik dan olahraga.';
      default:
        return 'Anak menunjukkan potensi yang beragam dan seimbang di berbagai area perkembangan.';
    }
  }
}
