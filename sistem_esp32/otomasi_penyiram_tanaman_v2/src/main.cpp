#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <time.h>
#include <LiquidCrystal_I2C.h>
#include <TM1637Display.h>
#include <RTClib.h>
#include <Encoder.h>
#include <Preferences.h>

//konfigurasi wifi
const char* ssid     = "MBAK ARTHA 4G";
const char* password = "sobatartha";
//konfigurasi ntp - waktu indonesia WIB
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 7 * 3600;
const int   daylightOffset_sec = 0;
//pengaturan waktu siram(setting 24 jam)
int jamSiram_1    = 10;
int menitSiram_1  = 00;
int jamSiram_2    = 15;
int menitSiram_2  = 00;
int durasiSiram = 10; //dalam menit

//pinout
LiquidCrystal_I2C lcd(0x27, 16, 2); //lcd i2c 16x2
#define rtc_SDA 21 //pin SDA RTC
#define rtc_SCL 22 //pin SCL RTC
#define CLK_tm1637 19 //pin CLK TM1637
#define DIO_tm1637 18 //pin DIO TM1637
TM1637Display tm(CLK_tm1637, DIO_tm1637); //display digit jam
#define relay_pin_1 25
#define relay_pin_2 26
#define clk_pin_encoder 32 //pin CLK rotary encoder
#define dt_pin_encoder 33 //pin DT rotary encoder
#define button_pin_set_waktu 34 //pin untuk set waktu siram
#define button_pin_onoff_otomatis 35 //on/off siram otomatis
#define button_pin_siram_manual 27 //pin siram manual

// // put function declarations here:
// int myFunction(int, int);

//tes lagi nanti ----
// rotary encoder state (updated in ISR)
volatile int8_t encoderDelta = 0;
portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;

void IRAM_ATTR handleEncoderISR() {
  int clk = digitalRead(clk_pin_encoder);
  int dt = digitalRead(dt_pin_encoder);
  // simple direction detection: when CLK changes, compare DT
  if (clk == dt) {
    encoderDelta++;
  } else {
    encoderDelta--;
  }
}
//-----

void setup() {
  // put your setup code here, to run once:
  // int result = myFunction(2, 3);

  //init serial monitor
  Serial.begin(115200);
  //init relay
  pinMode(relay_pin_1, OUTPUT);
  pinMode(relay_pin_2, OUTPUT);
  digitalWrite(relay_pin_1, HIGH);
  digitalWrite(relay_pin_2, HIGH);
  //init display
  lcd.init();
  lcd.backlight();
  tm.setBrightness(0x0f);
  tm.clear();
  //koneksi ke wifi
  lcd.setCursor(0, 0);
  lcd.print("Menyambungkan...");
  Serial.println("Menyambungkan...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  lcd.print("WiFi tersambung!");
  Serial.println("WiFi tersambung!");
  //sinkronisasi waktu dengan ntp
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  //tombol input
  pinMode(button_pin_set_waktu, INPUT_PULLUP);
  pinMode(button_pin_onoff_otomatis, INPUT_PULLUP);
  pinMode(button_pin_siram_manual, INPUT_PULLUP);
  //rotary encoder
  pinMode(clk_pin_encoder, INPUT_PULLUP);
  pinMode(dt_pin_encoder, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(clk_pin_encoder), handleEncoderISR, CHANGE);
  
}

void loop() {
  // put your main code here, to run repeatedly:
  //ambil waktu saat ini
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("Gagal mendapatkan waktu");
    return;
  }
  //tampilkan waktu di serial monitor dan lcd
  char timeStr[9];
  
  //cek kodingan besok ---
  // Persistent prefs (loaded once)
  static Preferences prefs;
  static bool prefsLoaded = false;
  static bool autoEnabled = true;
  static bool wateringActive = false;
  static unsigned long wateringEndMillis = 0;
  static int lastCheckedMinute = -1;
  static int lastWateredMinute = -1;
  if (!prefsLoaded) {
    prefs.begin("siram", false);
    jamSiram_1 = prefs.getInt("j1h", jamSiram_1);
    menitSiram_1 = prefs.getInt("j1m", menitSiram_1);
    jamSiram_2 = prefs.getInt("j2h", jamSiram_2);
    menitSiram_2 = prefs.getInt("j2m", menitSiram_2);
    durasiSiram = prefs.getInt("dur", durasiSiram);
    autoEnabled = prefs.getBool("auto", true);
    prefsLoaded = true;
  }

  // Button / setting handling
  enum SetMode {MODE_NONE=0, MODE_H1, MODE_M1, MODE_H2, MODE_M2, MODE_DUR};
  static SetMode setMode = MODE_NONE;
  static unsigned long lastButtonTime = 0;
  const unsigned long debounce = 50;
  static int lastSetButtonState = HIGH;
  static int lastIncButtonState = HIGH;
  static int lastManualButtonState = HIGH;

  int setBtn = digitalRead(button_pin_set_waktu);
  int incBtn = digitalRead(button_pin_onoff_otomatis);
  int manualBtn = digitalRead(button_pin_siram_manual);
  unsigned long nowMillis = millis();

  // set button: cycle through fields
  if (setBtn != lastSetButtonState && nowMillis - lastButtonTime > debounce) {
    lastButtonTime = nowMillis;
    if (setBtn == LOW) {
      if (setMode == MODE_NONE) setMode = MODE_H1;
      else if (setMode == MODE_H1) setMode = MODE_M1;
      else if (setMode == MODE_M1) setMode = MODE_H2;
      else if (setMode == MODE_H2) setMode = MODE_M2;
      else if (setMode == MODE_M2) setMode = MODE_DUR;
      else {
        setMode = MODE_NONE;
        // save settings
        prefs.putInt("j1h", jamSiram_1);
        prefs.putInt("j1m", menitSiram_1);
        prefs.putInt("j2h", jamSiram_2);
        prefs.putInt("j2m", menitSiram_2);
        prefs.putInt("dur", durasiSiram);
      }
    }
  }
  lastSetButtonState = setBtn;

  //tes lagi nanti----
  // handle rotary encoder adjustments when in set mode
  if (setMode != MODE_NONE) {
    int8_t delta = 0;
    portENTER_CRITICAL(&mux);
    delta = encoderDelta;
    encoderDelta = 0;
    portEXIT_CRITICAL(&mux);
    if (delta != 0) {
      // apply delta (can be multiple steps)
      if (setMode == MODE_H1) {
        int v = jamSiram_1 + delta;
        while (v < 0) v += 24;
        jamSiram_1 = v % 24;
      } else if (setMode == MODE_M1) {
        int v = menitSiram_1 + delta;
        while (v < 0) v += 60;
        menitSiram_1 = v % 60;
      } else if (setMode == MODE_H2) {
        int v = jamSiram_2 + delta;
        while (v < 0) v += 24;
        jamSiram_2 = v % 24;
      } else if (setMode == MODE_M2) {
        int v = menitSiram_2 + delta;
        while (v < 0) v += 60;
        menitSiram_2 = v % 60;
      } else if (setMode == MODE_DUR) {
        int v = durasiSiram + delta;
        if (v < 1) v = 1;
        if (v > 120) v = 120;
        durasiSiram = v;
      }
    }
  }
//--------

  // inc button: increment field or toggle auto
  if (incBtn != lastIncButtonState && nowMillis - lastButtonTime > debounce) {
    lastButtonTime = nowMillis;
    if (incBtn == LOW) {
      if (setMode == MODE_NONE) {
        autoEnabled = !autoEnabled;
        prefs.putBool("auto", autoEnabled);
      } else {
        if (setMode == MODE_H1) jamSiram_1 = (jamSiram_1 + 1) % 24;
        else if (setMode == MODE_M1) menitSiram_1 = (menitSiram_1 + 1) % 60;
        else if (setMode == MODE_H2) jamSiram_2 = (jamSiram_2 + 1) % 24;
        else if (setMode == MODE_M2) menitSiram_2 = (menitSiram_2 + 1) % 60;
        else if (setMode == MODE_DUR) durasiSiram = max(1, min(120, durasiSiram + 1));
      }
    }
  }
  lastIncButtonState = incBtn;

  // manual watering button: start watering immediately
  if (manualBtn != lastManualButtonState && nowMillis - lastButtonTime > debounce) {
    lastButtonTime = nowMillis;
    if (manualBtn == LOW) {
      wateringActive = true;
      wateringEndMillis = nowMillis + (unsigned long)durasiSiram * 60000UL;
      digitalWrite(relay_pin_1, LOW);
      digitalWrite(relay_pin_2, LOW);
    }
  }
  lastManualButtonState = manualBtn;

  // update watering state non-blocking
  if (wateringActive && nowMillis >= wateringEndMillis) {
    wateringActive = false;
    digitalWrite(relay_pin_1, HIGH);
    digitalWrite(relay_pin_2, HIGH);
  }

  // automatic watering on minute tick
  int curHour = timeinfo.tm_hour;
  int curMin = timeinfo.tm_min;
  if (curMin != lastCheckedMinute) {
    lastCheckedMinute = curMin;
    if (autoEnabled && !wateringActive) {
      if ((curHour == jamSiram_1 && curMin == menitSiram_1) || (curHour == jamSiram_2 && curMin == menitSiram_2)) {
        int key = curHour*100 + curMin;
        if (lastWateredMinute != key) {
          lastWateredMinute = key;
          wateringActive = true;
          wateringEndMillis = nowMillis + (unsigned long)durasiSiram * 60000UL;
          digitalWrite(relay_pin_1, LOW);
          digitalWrite(relay_pin_2, LOW);
        }
      }
    }
  }

  // display: show time or editing values
  static unsigned long lastBlink = 0;
  static bool blinkOn = true;
  if (nowMillis - lastBlink >= 500) { lastBlink = nowMillis; blinkOn = !blinkOn; }

  if (setMode == MODE_DUR) {
    // show duration as right two digits
    int minutes = durasiSiram % 100;
    int num = minutes;
    tm.showNumberDecEx(num, 0, true, 4, 0);
  } else {
    int showH = curHour;
    int showM = curMin;
    if (setMode == MODE_H1) showH = (blinkOn ? jamSiram_1 : curHour);
    else if (setMode == MODE_M1) showM = (blinkOn ? menitSiram_1 : curMin);
    else if (setMode == MODE_H2) showH = (blinkOn ? jamSiram_2 : curHour);
    else if (setMode == MODE_M2) showM = (blinkOn ? menitSiram_2 : curMin);
    int number = showH * 100 + showM;
    uint8_t colon = (blinkOn ? 0x40 : 0x00); //
    tm.showNumberDecEx(number, colon, true, 4, 0);
  }

  // small lcd status
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("Waktu:");
  sprintf(timeStr, "%02d:%02d", curHour, curMin);
  lcd.setCursor(6,0);
  lcd.print(timeStr);
  lcd.setCursor(0,1);
  if (autoEnabled) lcd.print("Auto:ON "); else lcd.print("Auto:OFF");
  lcd.setCursor(9,1);
  lcd.print("D:"); lcd.print(durasiSiram);
}
//-------

// // put function definitions here:
// int myFunction(int x, int y) {
//   return x + y;
// }