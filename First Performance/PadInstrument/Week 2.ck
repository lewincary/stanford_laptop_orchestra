// name: karptrak.ck
// desc: gametrak + stifkarp example
//
// author: Ge Wang (ge@ccrma.stanford.edu)
// date: spring 2014
//
// note: this is currently configured for 6 channels;
//       may need to do some wranglin' to make it work on stereo

// channel
2 => int CHANNELS;
// offset
0 => int CHAN_OFFSET;
// z axis deadzone
0 => float DEADZONE;
//Initialise Button
0 => int BUTTON;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;


// HID objects
Hid trak;
HidMsg msg;

// open joystick 0, exit on fail
if( !trak.openJoystick( device ) ) me.exit();

<<< "joystick '" + trak.name() + "' ready", "" >>>;

// data structure for gametrak
class GameTrak
{
    // timestamps
    time lastTime;
    time currTime;
    
    // previous axis data
    float lastAxis[6];
    // current axis data
    float axis[6];
}

// gametrack
GameTrak gt;

//Voices
5 => int VOICES;

SawOsc sharpy[VOICES] => ADSR envelope1 => LPF filty => Chorus choir => NRev wetrev => Gain gain1 => dac;

SinOsc sinny[VOICES] => envelope1 => filty => choir => wetrev => gain1 => dac;


//Noise white => filty => wetrev => gain1 => dac;

NRev kickrev => dac;

ADSR envelope2 => filty;


//Sawtooth Settings
for (int i; i < VOICES; i++) 
{
    0.01 => sharpy[i].gain;
}

//Sin Settings
for (int i; i < VOICES; i++) 
{
    0.01 => sinny[i].gain;
}


//Sawtooth envelope
(3::second, 3::second, .5, 4::second)  => envelope1.set;


//LPF settings
//1000 => filty.freq;
(5::second, 5::second, .5, 5::second)  => envelope2.set;

//Chorus settings
0.5 => choir.mix;
4 => choir.modDepth;
//70 => Std.mtof => choir.modFreq;

//Reverb Settings
0.5 => wetrev.mix;

//Final Gain settings
0.1 => gain1.gain;



//Woosh SndBuf
SndBuf woosh => dac;
me.sourceDir() + "woosh.wav" => string filename;
if( me.args() ) me.arg(0) => filename;
0.5 => woosh.gain;

//Kick SndBuf
SndBuf kick => dac;
me.sourceDir() + "sub.wav" => string kickname;
if( me.args() ) me.arg(0) => kickname;
0.5 => kick.gain;

//Cry SndBuf
SndBuf cry => dac;
me.sourceDir() + "cry.wav" => string cryname;
if( me.args() ) me.arg(0) => cryname;
0.5 => cry.gain;

//Clock SndBuf
SndBuf clock => NRev snarerev => dac;
me.sourceDir() + "snare.wav" => string clockname;
if( me.args() ) me.arg(0) => clockname;
0.5 => clock.gain;

//Snare Reverb Settings
0.5 => snarerev.mix;

// duration
150::ms => dur T;
// counter
int n;

// spork control
spork ~ gametrak();
//Keyboard

// print
spork ~ print();

// global
0 => float PITCH_OFFSET;

// main loop
while( true )
{
    //Button
    if (BUTTON == 1)
    {
        spork ~ newNote();
        0.5::second => now;
    }
    
    //Axis 0: (side to side) LPF Freq //pow keeps it positive and on an exponential scale
    if (gt.axis[0] < -0.3) { 
        clockname => clock.read;
        0.7::second => now;
    }
    if (gt.axis[0] > 0.3) { 
        cryname => cry.read;
        0.7::second => now;
    }
    
    //Axis 1: controls reverb (up and down  - absolute value)
    if (gt.axis[1] > 0.3) { 
        filename => woosh.read;
        0.7::second => now;
    }
    if (gt.axis[1] < -0.3) { 
        kickname => kick.read;
        0.7::second => now;
    }
   
    
    
    //Axis 2: (pull out) White Noise Generator
    if (gt.axis[2] > 0.02) {       
        //Math.pow((gt.axis[2] * 2), 2) => gain1.gain;
    } 
    
    //Axis 3: (side to side)  controls echo amount  
      
    Math.pow((gt.axis[3] * 100), 2) => filty.freq;
    
    //Axis 4: (up and down) controls pitch randomization
    Std.fabs(gt.axis[4]) => wetrev.mix;
    
    
    // pitch
    //Math.random2(30,30+Math.round((gt.axis[4]+1)*16-8)$int)*2 + PITCH_OFFSET => float pitch;
    //pitch => Std.mtof => belly.freq;
    
    //Axis 5: (pull out)
    
    if (gt.axis[5] > 0.01) {       
        Math.pow((gt.axis[5] * 2), 2) => gain1.gain;
        
    } else {
        //0 => belly.noteOff;
    } 
    
    100::ms => now;
    
    //to make sound bounce around using modular
    n++;
    CHANNELS %=> n;
}

//A Minor
int aminor[8];
81 => aminor[0]; //A
83 => aminor[1]; //B
84 => aminor[2]; //c
86 => aminor[3]; //d
88 => aminor[4]; //e
89 => aminor[5]; //f
91 => aminor[6]; //g
93 => aminor[7]; //a


//New Note
fun void newNote() 
{
    // choose freq
    for (int i; i < VOICES; i++) 
    {
        Math.random2( 70, 90 ) => float freq => Std.mtof  => sharpy[i].freq;
        freq - 12 => Std.mtof => sinny[i].freq;
    }
    
    
    // key on - start attack
    envelope1.keyOn();
    // advance time by 800 ms
    6.5::second => now;
    // key off - start release
    envelope1.keyOff();
    // advance time by 800 ms
    4::second => now;
}

// print
fun void print()
{
    // time loop
    while( true )
    {
        // values
        <<< "axes:", gt.axis[0],gt.axis[1],gt.axis[2],
        gt.axis[3],gt.axis[4],gt.axis[5] >>>;
        // advance time
        100::ms => now;
    }
}

//Keyboard Handling
fun void midikeyboard() 
{
    
    
}

// gametrack handling
fun void gametrak()
{
    while( true )
    {
        // wait on HidIn as event
        trak => now;
        
        // messages received
        while( trak.recv( msg ) )
        {
            // joystick axis motion
            if( msg.isAxisMotion() )
            {            
                // check which
                if( msg.which >= 0 && msg.which < 6 )
                {
                    // check if fresh
                    if( now > gt.currTime )
                    {
                        // time stamp
                        gt.currTime => gt.lastTime;
                        // set
                        now => gt.currTime;
                    }
                    // save last
                    gt.axis[msg.which] => gt.lastAxis[msg.which];
                    // the z axes map to [0,1], others map to [-1,1]
                    if( msg.which != 2 && msg.which != 5 )
                    { msg.axisPosition => gt.axis[msg.which]; }
                    else
                    { 1 - ((msg.axisPosition + 1) / 2) => gt.axis[msg.which];
                    if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which]; }
                }
            }
            
            // joystick button down
            else if( msg.isButtonDown() )
            {
                // <<< "button", msg.which, "down" >>>;
                1 => BUTTON;
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {
                // <<< "button", msg.which, "up" >>>;
                0 => BUTTON;
            }
        }
    }
}