import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenAIService {
  // PENTING: Sebaiknya API Key tidak dismpan hardcode di sini, tapi di .env
  // Namun untuk refactor ini kita ikuti existing code.
  static const String _apiKey =
      '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';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String?> describeImage(String base64Image,
      {required String mode}) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": mode == "visual"
                      ? "Deskripsikan isi gambar ini secara rinci untuk penyandang tunanetra. Fokus pada elemen visual utama seperti objek, warna, bentuk, dan tata letak. Jika ada teks, baca teksnya tanpa memproses atau menyimpan informasi pribadi seperti nama, alamat, atau nomor identitas. Hindari asumsi atau interpretasi subjektif, dan berikan deskripsi yang objektif dan terstruktur untuk membantu memahami konteks gambar."
                      : "Ekstrak teks dari gambar ini dengan akurat dan berikan hasilnya secara langsung tanpa menambahkan simbol atau penolakan.",
                },
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
                },
              ],
            },
          ],
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'];
      } else {
        print("OpenAI Error: ${response.statusCode} - ${response.body}");
        return 'Gagal mendapatkan deskripsi: ${response.statusCode}';
      }
    } catch (e) {
      print("Error calling OpenAI: $e");
      return "Kesalahan saat memproses gambar: $e";
    }
  }
}
