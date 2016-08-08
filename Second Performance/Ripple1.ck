// name: ripple.ck
// desc: gametrak + stifkarp example
//
// author: Ge Wang (ge@ccrma.stanford.edu)
// date: spring 2014
//
// note: this is currently configured for 6 channels;
//       may need to do some wranglin' to make it work on stereo


6 => int CHANNELS;
// z axis deadzone
0 => float DEADZONE;
//Initialise Button
0 => int BUTTON;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

//Keyboard input
Hid hi;
HidMsg keymsg;

// which keyboard
0 => int keyboardDevice;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => keyboardDevice;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( keyboardDevice ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;




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


//========================Setup==============================//

StifKarp moogy[CHANNELS];
ADSR envelope1[CHANNELS];
NRev revvy[CHANNELS];
Delay delly[CHANNELS];
Gain gain1[CHANNELS];
SndBuf ping[CHANNELS];

for (int i; i < CHANNELS; i++)
{
    //Patch
    moogy[i] => revvy[i] => delly[i] => gain1[i] => dac.chan(i);
    
    //Settings
    //Sawtooth envelope
    //(3::second, 3::second, .5, 4::second)  => envelope1[i].set;
}
    


//Ping SndBuf
me.sourceDir() + "woosh.wav" => string filename;
if( me.args() ) me.arg(0) => filename;


//========================Setup complete ==============================//





// duration
150::ms => dur T;


// spork control
spork ~ gametrak();
spork ~ computerKeyboard();


//Parameters to take in:
//whether or not delay is turned on
//playback speed

//String controls an envelope that opens up if the string is longer,
//and short if not

//=====CHORDS=======//
[ 61, 63, 66, 68, 70 ] @=> int pentaScale[];


//Incoming Parameters
1 => float NOTE_VELOCITY;
60 => int NOTE_FREQUENCY;
0 => int NOTE_DELAY;



// main loop
while( true )
{
    for (int i; i < CHANNELS; i++)
    {
        if (gt.axis[5] > 0.02)
        {
            if (gt.axis[3] < -0.6) { 
                setNote(0);
            }
            if (gt.axis[3] < -0.3 && gt.axis[3] > -0.6) { 
                setNote(1);
            }
            if (gt.axis[3] > -0.3 && gt.axis[3] < 0.3) { 
                setNote(2);
            }
            if (gt.axis[3] > 0.3 && gt.axis[3] < 0.6) { 
                setNote(3);
            }
            if (gt.axis[3] > 0.6) { 
                setNote(4);
            }
            NOTE_VELOCITY => moogy[i].pluck;
        }
    } 
    1::second => now;
    
}



fun void setNote(int note)
{
    for (int i; i < CHANNELS; i++)
    {
    pentaScale[note] => Std.mtof => moogy[i].freq;
}
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
fun void computerKeyboard() 
{
    while( true )
    {
        // wait for event
        hi => now;
        
        // get message
        while( hi.recv( keymsg ) )
        {
            // check
            if( keymsg.isButtonDown() )
            {
                //keymsg.ascii - 48 => chordBank;
                //<<< chordBank >>>;
            }
        }
    }
    
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
                
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {
                // <<< "button", msg.which, "up" >>>;
               
            }
        }
    }
}