#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>

// SSID dan Password WiFi
const char* ssid = "IAF";
const char* password = "imam887588";

// Daftar URL server (menghapus Button 1 dan Button 4)
const char* serverNames[] = {
  "https://5a02880d2f1b.ngrok-free.app/button2",  // Button 2
  "https://5a02880d2f1b.ngrok-free.app/button3",  // Button 3
  "https://5a02880d2f1b.ngrok-free.app/button5",  // Button 5
  "https://5a02880d2f1b.ngrok-free.app/button6",  // Button 6
  "https://5a02880d2f1b.ngrok-free.app/button7"   // Button 7
};

// Pin yang digunakan untuk tombol
const int buttonPins[] = {25, 26, 12, 15, 13, 27, 14};

// Inisialisasi objek WiFiClientSecure
WiFiClientSecure client;

void setup() {
  Serial.begin(115200);  // Mulai komunikasi serial dengan baudrate 115200
  
  // Set pin tombol sebagai INPUT_PULLUP
  for (int i = 0; i < 7; i++) {
    pinMode(buttonPins[i], INPUT_PULLUP);
  }
  
  // Menghubungkan ke WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);  // Tunggu 1 detik
    Serial.println("Connecting to WiFi...");
  }
  
  // Setelah terhubung
  Serial.println("Connected to WiFi");
  Serial.println("ESP32 IP: " + WiFi.localIP().toString());

  // Menonaktifkan verifikasi sertifikat SSL
  client.setInsecure();
}

void loop() {
  for (int i = 0; i < 7; i++) {
    if (digitalRead(buttonPins[i]) == LOW) {  // Jika tombol ditekan (LOW)
      
      // Button 1 dan Button 4 hanya mencetak ke Serial Monitor
      if (i == 0 || i == 3) {  // Button 1 (i == 0) dan Button 4 (i == 3)
        Serial.println("ON_" + String(i + 1) );
      } else {
        // Untuk tombol lainnya, kirim permintaan HTTP GET
        Serial.println("ON_" + String(i + 1));
        
        HTTPClient http;
        http.begin(client, serverNames[i - (i > 2 ? 1 : 0)]);  // Menyesuaikan indeks serverNames untuk tombol yang lebih besar dari 2
        http.setTimeout(10000);  // Set timeout ke 10 detik
        http.addHeader("User-Agent", "Mozilla/5.0 (compatible; ESP32-HTTP-Client/1.0)");
        
        // Mengirimkan GET request
        int httpResponseCode = http.GET();
        
        // Menampilkan respon dari server
        if (httpResponseCode > 0) {
          Serial.print("HTTP Response code for button ");
          Serial.print(i + 1);
          Serial.print(": ");
          Serial.println(httpResponseCode);
          Serial.println("Response: " + http.getString());
        } else {
          // Menampilkan pesan error jika request gagal
          Serial.print("Error sending GET request for button ");
          Serial.print(i + 1);
          Serial.print(": ");
          Serial.println(http.errorToString(httpResponseCode));
          Serial.println("Server: " + String(serverNames[i - (i > 2 ? 1 : 0)]));
        }
        http.end();  // Menutup koneksi HTTP
      }
      
      // Memberikan delay 500ms untuk menghindari bouncing tombol
      delay(500);
    }
  }
}
