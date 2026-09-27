#include <WiFi.h>
#include <WebServer.h>
#include "DHT.h"

#define DHTPIN 14       // Chân Data của DHT11 nối với chân GPIO 14 của ESP32
#define DHTTYPE DHT11   // Khai báo loại cảm biến là DHT11

DHT dht(DHTPIN, DHTTYPE);

const int ledPin = 23;            // Chân điều khiển đèn LED nối với GPIO 23
const float thresholdTemp = 30.0; // Ngưỡng nhiệt độ bật đèn tự động (30°C)

// ⚠️ HÃY THAY TÊN WIFI 2.4GHz VÀ MẬT KHẨU CỦA BẠN VÀO ĐÂY
const char* ssid = "_hhau.05_";
const char* password = "00000000";

WebServer server(80);

// Hàm xử lý khi ứng dụng Flutter gọi đường dẫn /data
void handleData() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    server.send(500, "application/json", "{\"error\":\"Failed to read DHT\"}");
    return;
  }

  // Logic tự động bật/tắt đèn LED theo ngưỡng nhiệt độ
  if (t >= thresholdTemp) {
    digitalWrite(ledPin, HIGH);
  } else {
    digitalWrite(ledPin, LOW);
  }

  int ledState = digitalRead(ledPin);

  // Đóng gói dữ liệu thành chuẩn JSON để gửi về app Flutter
  String json = "{";
  json += "\"temperature\":" + String(t, 1) + ",";
  json += "\"humidity\":" + String(h, 1) + ",";
  json += "\"led\":" + String(ledState);
  json += "}";

  server.send(200, "application/json", json);
}

// Hàm xử lý khi ứng dụng Flutter bấm nút bật/tắt đèn thủ công qua đường dẫn /led
void handleLed() {
  if (server.hasArg("state")) {
    String state = server.arg("state");
    if (state == "on") {
      digitalWrite(ledPin, HIGH);
      server.send(200, "text/plain", "LED ON");
    } else {
      digitalWrite(ledPin, LOW);
      server.send(200, "text/plain", "LED OFF");
    }
  } else {
    server.send(400, "text/plain", "Bad Request");
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  dht.begin();

  // Kết nối Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP()); // 📌 GHI LẠI ĐỊA CHỈ IP NÀY ĐỂ ĐIỀN VÀO APP FLUTTER

  // Định nghĩa các đường dẫn API cho Web Server
  server.on("/data", HTTP_GET, handleData);
  server.on("/led", HTTP_GET, handleLed);
  
  server.begin();
  Serial.println("Web server started");
}

void loop() {
  server.handleClient(); // Lắng nghe yêu cầu kết nối từ ứng dụng di động
}