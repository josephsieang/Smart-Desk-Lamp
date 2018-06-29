void setup()

{

Serial.begin(9600);
pinMode(2 , OUTPUT);
pinMode(3 , OUTPUT);

}

void loop()

{

unsigned int AnalogValue;

AnalogValue = analogRead(A0);

AnalogValue = map( AnalogValue , 0 , 1023 , 0, 255);
AnalogValue = constrain( AnalogValue , 0 , 255);

if( AnalogValue >= 0 && AnalogValue <= 40) 
{
  digitalWrite( 2, HIGH);
  digitalWrite( 3, LOW);
  Serial.println( AnalogValue);
  Serial.println("bright");
  delay(1000);
}
//Serial.println(AnalogValue);
else if ( AnalogValue > 40 && AnalogValue <= 80)
{
  digitalWrite( 2, LOW);
  digitalWrite( 3, HIGH);
  Serial.println( AnalogValue);
  Serial.println("medium");
  delay(1000);
}
else if ( AnalogValue > 80 && AnalogValue <= 120)
{
  digitalWrite( 2, LOW);
  digitalWrite( 3, LOW);
  Serial.println( AnalogValue);
  Serial.println("dark");
  delay(1000);
}
else
{
  digitalWrite( 2, HIGH);
  digitalWrite( 3, HIGH);
  Serial.println( AnalogValue);
  Serial.println("OFF");
  delay(1000);
}
}
