#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <time.h>
#include <LiquidCrystal_I2C.h>
#include <TM1637Display.h>
#include <RTClib.h>


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
#define button_pin_set_waktu 34 //pin untuk set waktu siram
#define button_pin_onoff_otomatis 35 //on/off siram otomatis
#define button_pin_siram_manual 27 //pin siram manual

// // put function declarations here:
// int myFunction(int, int);

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
  
}

// // put function definitions here:
// int myFunction(int x, int y) {
//   return x + y;
// }