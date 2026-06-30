/*
  Signal Defense Kit: joystick + four button controller

  Sends one plain-text command per line over USB serial:
  UP, DOWN, LEFT, RIGHT, SPACE, E, SHIFT, R

  Default wiring:
  - Joystick VRx    -> A0
  - Joystick VRy    -> A1
  - Place button    -> D2 and GND, sends SPACE
  - Switch button   -> D3 and GND, sends E
  - Remove button   -> D4 and GND, sends SHIFT
  - Restart button  -> D5 and GND, sends R
  - Joystick GND    -> GND
  - Joystick +5V    -> 5V
*/

const int JOYSTICK_X_PIN = A0;
const int JOYSTICK_Y_PIN = A1;

struct ButtonBinding {
  int pin;
  const char* command;
  bool previousPressed;
  unsigned long lastChangeMs;
};

ButtonBinding buttons[] = {
  {2, "SPACE", false, 0},
  {3, "E", false, 0},
  {4, "SHIFT", false, 0},
  {5, "R", false, 0},
};

const int BUTTON_COUNT = sizeof(buttons) / sizeof(buttons[0]);

const long BAUD_RATE = 115200;
const int DEADZONE = 170;
const unsigned long MOVE_REPEAT_MS = 180;
const unsigned long BUTTON_DEBOUNCE_MS = 45;

// Flip these if your joystick direction is reversed.
const bool INVERT_X = false;
const bool INVERT_Y = false;

int centerX = 512;
int centerY = 512;
unsigned long lastMoveMs = 0;

void setup() {
  for (int i = 0; i < BUTTON_COUNT; i++) {
    pinMode(buttons[i].pin, INPUT_PULLUP);
  }
  Serial.begin(BAUD_RATE);
  delay(600);
  calibrateJoystickCenter();
}

void loop() {
  readJoystick();
  readButtons();
}

void calibrateJoystickCenter() {
  long totalX = 0;
  long totalY = 0;
  const int samples = 24;

  for (int i = 0; i < samples; i++) {
    totalX += analogRead(JOYSTICK_X_PIN);
    totalY += analogRead(JOYSTICK_Y_PIN);
    delay(5);
  }

  centerX = totalX / samples;
  centerY = totalY / samples;
}

void readJoystick() {
  int x = analogRead(JOYSTICK_X_PIN) - centerX;
  int y = analogRead(JOYSTICK_Y_PIN) - centerY;

  if (INVERT_X) {
    x = -x;
  }
  if (INVERT_Y) {
    y = -y;
  }

  if (millis() - lastMoveMs < MOVE_REPEAT_MS) {
    return;
  }

  if (abs(x) < DEADZONE && abs(y) < DEADZONE) {
    return;
  }

  if (abs(x) > abs(y)) {
    Serial.println(x < 0 ? "LEFT" : "RIGHT");
  } else {
    Serial.println(y < 0 ? "UP" : "DOWN");
  }

  lastMoveMs = millis();
}

void readButtons() {
  unsigned long now = millis();

  for (int i = 0; i < BUTTON_COUNT; i++) {
    bool buttonPressed = digitalRead(buttons[i].pin) == LOW;

    if (buttonPressed != buttons[i].previousPressed && now - buttons[i].lastChangeMs >= BUTTON_DEBOUNCE_MS) {
      buttons[i].previousPressed = buttonPressed;
      buttons[i].lastChangeMs = now;

      if (buttonPressed) {
        Serial.println(buttons[i].command);
      }
    }
  }
}
