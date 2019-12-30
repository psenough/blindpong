
//
// original processing pong implementation: 
// "Just Another Pong" by Moritz Ufer
// http://www.openprocessing.org/visuals/?visualID=2270
//
// hacked with sound by ps
// hacked with arduino potenciometer by PAngelo
// quality control by Mauricio
// "Blind Pong" for Codebits 2010
//

//
// 
//  ,----.  ,-.     ,-. ,--. ,-. ,----.
//  |  .  ) | |     '-´ |   \| | |  .  \
//  |    <  | |     ,-. | |\ \ | |  |  |
//  |  o  ) | |____ | | | | \  | |  |  |
//  '____/  '_____/ '_' '_'  \_' '____/
//
//
//  ,----.   ,--.  ,--. ,-.  ,-----.
//  |  .  ) | .. | |   \| | |  ,---'
//  |   _/  | || | | |\ \ | | |  __.
//  |  |    | '' | | | \  | '  \_\ /
//  '__'     \__/  '_'  \_'  \____/
//
//

import ddf.minim.*;
import ddf.minim.signals.*;
import processing.serial.*;

Minim minim;
AudioOutput out;
SineWave sine;
SineWave saw;
AudioSample win;
AudioSample lose;
AudioSample tick;
AudioSample youwin;
AudioSample youlose;

boolean silentnight = false;
int silence;

float paddle1Volume = 0.4;
float ballVolume = 0.3;

// Pot data
int pot_min = 0;
int pot_max = 255;
int pot_value = 0;
Serial pot_connection;

PFont font;
int errorangle;
boolean leftdirection; // if the ball is moving left it returns true
boolean isthereapaddle; // if there is a paddle this value returns true
int position_count; // x for the postion of paddle 1
int nothingtodo;  // it counts when the oppenent has nothing to do and makes it a bit more humanlike
float playaround; // this constant ramdomizes the opponent and makes it a bit more humanlike
float ball_speed = 3;
float ball_acceleration = .3;
float ball_angle = 0;
float ball_spin = 0;
float dx;
float dy;
//starting postiions
float ball_x = 300;
float ball_y = 200;
// paddle1 variables
float paddle1 = height/2;
float abletomove_paddle1 = 0; // after touching the ball this value makes it able to change angle and speed
float positionstore_paddle1; // stores the position of paddle 1 every x pictures difference of paddle1 and this can used as speed of the paddle
float paddle1_mov; // difference between positionstore_paddle1 and paddle1's actual position
float paddle1_mod_angle;
float paddle1_mod_speed;
float paddle1_mod_spin = 0;
int toggle = 20; // how fast must your paddle be
float paddle2 = height/2;
float abletomove_paddle2 = 0; // after touching the ball this value makes it able to change angle and speed
float positionstore_paddle2; // stores the position of paddle 1 every x pictures difference of paddle1 and this can used as speed of the paddle
float paddle2_mov; // difference between positionstore_paddle1 and paddle1's actual position
float paddle2_mod_angle;
float paddle2_mod_speed;
float paddle2_mod_spin = 0;

int score1 = 0;
int score2 = 0;

int ourwidth = 600;
int ourheight = 400;

void setup() {
  frameRate(30);
  noStroke();
  size(ourwidth, ourheight);
  background(0);
  // font = loadFont("AcknowledgeTT-BRK--48.vlw");
  font = loadFont("SynchroLET-48.vlw");

  minim = new Minim(this);
  out = minim.getLineOut(Minim.STEREO, 512);
  // create a sine wave Oscillator, set to 440 Hz, at 0.5 amplitude, 
  // sample rate 44100 to match the line out
  sine = new SineWave(440, paddle1Volume, 44100);
  sine.setPan(-1);
  saw = new SineWave(440, ballVolume, 44100);
  // add the oscillator to the line out
  out.addSignal(sine);
  out.addSignal(saw);


  win = minim.loadSample("win.wav", 2048);
  if ( win == null ) println("Didn't get win.wav!");

  lose = minim.loadSample("lose.wav", 2048);
  if ( lose == null ) println("Didn't get lose!");

  tick = minim.loadSample("tick.wav", 2048);
  if ( tick == null ) println("Didn't get tick!");

  youwin = minim.loadSample("youwin.wav", 2048);
  if ( youwin == null ) println("Didn't get youwin.wav!");

  youlose = minim.loadSample("youlose.wav", 2048);
  if ( youlose == null ) println("Didn't get youlose!");

 // pot_connection = new Serial(this, "COM10", 115200);
  print Serial.available();
}

void draw() {
  pot_connection.write ('r');
  while (pot_connection.available() < 1) {
    delay (10);
  }
  pot_value = pot_connection.read();

  fill(0, (165-4*ball_speed));
  rect(0, 0, width, height);
  smooth();
  fill(255,50);
  textFont(font, 32);
  textAlign(CENTER);
  text(score1 + " : " + score2, width/2, 30);
  fill(255);
  leftdirection = ball_angle > 270 || ball_angle < 90;
  isthereapaddle = ball_y >= paddle1 && ball_y <=(paddle1 + 100);

  // get paddles movement
  position_count++;
  if(position_count > 1) // stores every 2 frames
  {
    position_count = 0;
    positionstore_paddle1 = paddle1;
    positionstore_paddle2 = paddle2;
  }
  paddle1_mov += paddle1 - positionstore_paddle1;
  paddle2_mov += paddle2 - positionstore_paddle2;

  //paddle lefthandside
  rect(15, paddle1, 5, 100);
  //paddle1 = mouseY-30;
  paddle1 = map (pot_value, pot_min, pot_max, 0, height) - 30;

  //paddle1 speed and angle modifications
  // what paddle1 movement provokes
  paddle1_mod_angle  = exp(-pow((abs(paddle1_mov)-toggle),2)/(toggle*10));
  paddle1_mod_speed  = exp(-pow((abs(paddle1_mov)-2.5*toggle),2)/(toggle*20));
  paddle1_mod_spin = exp(-pow((abs(paddle1_mov)-3*toggle),2)/(toggle*10));

  if(leftdirection)
  {
    abletomove_paddle1 *= exp(-pow(ball_x,2)/7000); // how long can the ball be manipulated depending on ball_x . .  ball_x = 0 -=> abletomove_paddle1 =1 when ball is hit
  }
  // modifies the ball_angle when the ball is hit by a moving paddle
  // the sharper the angle the more difficult it is to get it even more sharper.
  if(paddle1_mov > 0)
  {
    ball_angle += paddle1_mov*abletomove_paddle1*paddle1_mod_angle*abs(ball_angle-90)/270;
  }
  if(paddle1_mov < 0)
  {
    ball_angle += paddle1_mov*abletomove_paddle1*paddle1_mod_angle*abs(270-ball_angle)/270;
  }

  //1.5 times of the ball_speed when abletomove_paddle1 and paddle_mod_speed are both at value 1  
  ball_acceleration += 1.8*abletomove_paddle1*paddle1_mod_speed;
  ball_acceleration = pow(ball_acceleration, 0.994); // ballspeed slows down to its old value
  ball_speed = 5*ball_acceleration;

  //the famous spin shot. when ball is hit with paddle speed around 60, ball gets some spin, by adding ball_spin to the ball angle
  if(paddle1_mov > 0)
  {
    ball_spin += 2*paddle1_mod_spin*abletomove_paddle1;
  }
  if(paddle1_mov < 0)
  {
    ball_spin += -2*paddle1_mod_spin*abletomove_paddle1;
  }
  ball_angle += ball_spin;
  ball_spin *= 0.92;


  paddle1_mov *= 0.6; // paddle1 movement slows rapidly down when no more mouse action happens


  //paddle righthandside
  rect(580, paddle2, 5, 60);
  //paddle2 speed and angle modifications
  // what paddle2 movement provokes
  paddle2_mod_angle  = exp(-pow((abs(paddle2_mov)-toggle),2)/(toggle*10));
  paddle2_mod_speed  = exp(-pow((abs(paddle2_mov)-2.5*toggle),2)/(toggle*20));
  paddle2_mod_spin = exp(-pow((abs(paddle2_mov)-3*toggle),2)/(toggle*10));

  if(!leftdirection)
  {
    abletomove_paddle2 *= exp(-pow(ball_x-width,2)/7000); // how long can the ball be manipulated depending on ball_x . .  ball_x = 0 -=> abletomove_paddle1 =1 when ball is hit
  }
  // modifies the ball_angle when the ball is hit by a moving paddle
  // the sharper the angle the more difficult it is to get it even more sharper.
  if(paddle2_mov > 0)
  {
    ball_angle -= paddle2_mov*abletomove_paddle2*paddle2_mod_angle*abs(ball_angle-90)/270;
  }
  if(paddle2_mov < 0)
  {
    ball_angle -= paddle2_mov*abletomove_paddle2*paddle2_mod_angle*abs(270-ball_angle)/270;
  }

  //1.5 times of the ball_speed when abletomove_paddle1 and paddle_mod_speed are both at value 1  
  ball_acceleration += 1.8*abletomove_paddle2*paddle2_mod_speed;
  ball_acceleration = pow(ball_acceleration, 0.994); // ballspeed slows down to its old value
  ball_speed = 4*ball_acceleration;

  //the famous spin shot. when ball is hit with paddle speed around 60, ball gets some spin, by adding ball_spin to the ball angle
  if(paddle2_mov > 0)
  {
    ball_spin += -2*paddle2_mod_spin*abletomove_paddle2;
  }
  if(paddle2_mov < 0)
  {
    ball_spin += 2*paddle2_mod_spin*abletomove_paddle2;
  }
  ball_angle += ball_spin;
  ball_spin *= 0.92;


  paddle2_mov *= 0.6; // paddle1 movement slows rapidly down when no more mouse action happens

  //right paddle movement AI
  // reaction
  if(leftdirection && ball_x > 500)
  {
    playaround=0;
    paddle2 += (ball_y - paddle2-30) * ball_x/(2000+ball_speed*90);
  }
  // notthing to do ball is in direction towards player and in range 300
  nothingtodo++;
  if ((nothingtodo >29-abs(playaround)) && !leftdirection )
  {
    nothingtodo = 0;
    if(ball_x > 550)
    {
      playaround = abs(random(-1,1))*random(65-(ball_speed*3),75 - ball_speed);
    }
    else
    {
      playaround = random(-5,5);
    }
  }
  if(paddle2 >= 340)
  {
    playaround = -10;
  }
  if(paddle2 <= 0)
  {
    playaround = 10;
  }


  paddle2 += playaround;



  //ball movement x-axis and paddle reflection
  if(ball_angle > 360)
  {
    ball_angle -= 360;
  }
  if(ball_angle < 0)
  { 
    ball_angle += 360;
  }

  ball_x += ball_speed*cos(radians(ball_angle));
  ball_y += ball_speed*sin(radians(ball_angle));     

  if( ball_x <= 20 && !leftdirection && ((ball_y >= paddle1 && ball_y <=(paddle1 + 100)) || (ball_y >= positionstore_paddle1 && ball_y <=(positionstore_paddle1 + 100))))
  {
    abletomove_paddle1 = 1;
    ball_angle += (90-ball_angle)*2;

    win.trigger();
  }
  else if( ball_x >= 580 && (ball_y >= paddle2 && ball_y <= (paddle2 + 60))&& leftdirection)
  {
    abletomove_paddle2 = 1;
    ball_angle += (90-ball_angle)*2;
  }

  if(errorangle > 240 || ball_x <  10 || ball_x > width-10) //initialize ball
  {
    if(ball_x > width/2) {
      dx= 180; 
      score1++;
      silentnight = true;
      silence = millis();
    }
    else if(ball_x < width/2) {
      dx = 0; 
      score2++;
      silentnight = true;
      silence = millis();
    }
    ball_x = width/2;
    ball_y = height/2;

    ball_angle = random(0,45)+dx;
    ball_acceleration = 1;
    ball_spin = 0;
    errorangle = 0;

    lose.trigger();
  }
  if(abs(ball_speed*cos(radians(ball_angle))) < 0.6 )
  {
    text("too hard angle",width/2,height/2);
    errorangle++;
  }



  //ball movement y-axis and x-walls
  if(ball_y < 0 || ball_y > 395) {
    ball_angle += -ball_angle*2;
    tick.trigger();
  }



  ellipseMode(CENTER);
  fill(255-ball_speed, 255-(ball_speed-5)*5, 255-(ball_speed-5)*25);
  rect(ball_x, ball_y+(random(0,pow(ball_speed,2)*0.01)), 10, 10);
  dy =round(paddle1_mov);

  if(score1 > 10)
  {
    fill(0);
    rect(0, 0, width, height);
    fill(255);
    textFont(font, 32);
    textAlign(CENTER);
    text("YOU WIN\n click to play again", width/2, height/2);
    saw.setAmp( 0 );
    sine.setAmp ( 0 );
    youwin.trigger();
    noLoop();
  }
  if(score2 > 10)
  {
    fill(0);
    rect(0, 0, width, height);
    fill(255);
    textFont(font, 32);
    textAlign(CENTER);
    text("YOU LOSE\n click to play again", width/2, height/2);
    saw.setAmp( 0 );
    sine.setAmp ( 0 );
    youlose.trigger();
    noLoop();
  }


  //sound

  saw.setFreq(440*3 - (ball_y/ourheight)*440*3);
  saw.setPanNoGlide((ball_x/ourwidth)*2-1);

  sine.setFreq(440*3 - (paddle1/ourheight)*440*3);

  int time = millis() % 500;
  //print(time + "\n");

  if (silentnight) { 
    float thissilence = millis();
    if ((thissilence-silence) > 2000) silentnight = false;
    saw.setAmp(0);
  } 
  else {
    //  if (time < 300) sine.setAmp( paddle1Volume );
    //   else sine.setAmp( 0 );

    if (time < 300) saw.setAmp( ballVolume );
    else saw.setAmp( 0 );
  }
}

void mouseClicked()
{
  if(score1>10 || score2>10)
  {
    score1 =0;
    score2 = 0;
    ball_x = width/2;
    ball_y = height/2;

    ball_angle = random(0,45)+dx;
    ball_acceleration = 1;
    ball_spin = 0;

    saw.setAmp( ballVolume );
    sine.setAmp( paddle1Volume );

    loop();
  }
}


void stop()
{
  win.close();
  lose.close();
  tick.close();  
  youwin.close();
  youlose.close();
  // always close audio I/O classes
  //in.close();
  out.close();
  // always stop your Minim object
  minim.stop();

  super.stop();
}

