#include "WProgram.h"
void 
setup();
void 
loop();
const int POT = 0;

void 
setup()
{
  Serial.begin (115200);
}

void 
loop() {
  if (Serial.available() <= 0) { 
    delay (10);
    return;
  }
  byte cmd = Serial.read();
  if (cmd == 'r') {
    int val = analogRead (POT);  
    Serial.print (val / 4, BYTE);
  }
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

