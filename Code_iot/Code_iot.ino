#include <WiFi.h>
#include <WebServer.h>
#include "DHT.h"

#define DHTPIN 14
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);
const int ledPin = 23;
const float thresholdTemp = 30.0;

// ⚠️ ĐIỀN WIFI VÀ MẬT KHẨU CỦA BẠN VÀO ĐÂY
const char* ssid = "Bekind Coffee";
const char* password = "camonquykhach";

WebServer server(80);
bool isAutoMode = true;

void handleData() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    server.send(500, "application/json", "{\"error\":\"Failed to read DHT\"}");
    return;
  }

  // 🚨 TƯ DUY CẢNH BÁO AN TOÀN TUYỆT ĐỐI (OVERRIDE)
  if (t >= thresholdTemp) {
    // 1. Nếu quá nhiệt: ÉP BUỘC bật đèn dù đang ở chế độ nào
    digitalWrite(ledPin, HIGH);
  } else {
    // 2. Nếu an toàn (dưới 30 độ):
    if (isAutoMode) {
      digitalWrite(ledPin, LOW); // Đang Auto thì tự tắt đèn
    }
    // Nếu không Auto (Manual) thì giữ nguyên trạng thái do người dùng đang bấm
  }

  int ledState = digitalRead(ledPin);

  String json = "{";
  json += "\"temperature\":" + String(t, 1) + ",";
  json += "\"humidity\":" + String(h, 1) + ",";
  json += "\"led\":" + String(ledState) + ",";
  json += "\"isAuto\":" + String(isAutoMode ? "true" : "false");
  json += "}";

  server.send(200, "application/json", json);
}

void handleLed() {
  if (server.hasArg("state")) {
    float t = dht.readTemperature();
    String state = server.arg("state");

    // 🚨 BẢO MẬT: Chặn người dùng tắt đèn nếu đang trong tình trạng nguy hiểm
    if (t >= thresholdTemp && state == "off") {
      server.send(403, "text/plain", "EMERGENCY: Cannot turn off alarm!");
      return;
    }

    if (state == "on") {
      digitalWrite(ledPin, HIGH);
    } else {
      digitalWrite(ledPin, LOW);
    }
    server.send(200, "text/plain", "LED OK");
  } else {
    server.send(400, "text/plain", "Bad Request");
  }
}

void handleMode() {
  if (server.hasArg("auto")) {
    String mode = server.arg("auto");
    if (mode == "true") {
      isAutoMode = true;
    } else {
      isAutoMode = false;
    }
    server.send(200, "text/plain", "Mode Updated");
  } else {
    server.send(400, "text/plain", "Bad Request");
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  server.on("/data", HTTP_GET, handleData);
  server.on("/led", HTTP_GET, handleLed);
  server.on("/mode", HTTP_GET, handleMode);

  server.begin();
  Serial.println("Web server started");
}

void loop() {
  server.handleClient();
}