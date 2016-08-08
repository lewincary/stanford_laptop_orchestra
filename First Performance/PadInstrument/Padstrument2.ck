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
//Keyboard input
Hid hi;
HidMsg keymsg;


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


NRev kickrev => dac;

ADSR envelope2 => filty;


//Sawtooth Settings
for (int i; i < VOICES; i++) 
{
    0.003 => sharpy[i].gain;
}

//Sin Settings
for (int i; i < VOICES; i++) 
{
    0.003 => sinny[i].gain;
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


//Arp Settings
StifKarp mandy[CHANNELS];
for( int i; i < CHANNELS; i++ )
{
    mandy[i] => NRev snarerev => dac.chan(i);
    0.3 => mandy[i].gain;
    //Snare Reverb Settings
    0.2 => snarerev.mix;
}




// duration
150::ms => dur T;
// counter
int n;

// spork control
spork ~ gametrak();
spork ~ computerKeyboard();
//Keyboard

// print
// spork ~ print();

// global
0 => float PITCH_OFFSET;

[ 81, 83, 84, 86, 88, 89, 91, 93 ] @=> int aminor[];
[ 81, 84, 88, 84 ] @=> int achord[];
[ 86, 89, 93, 89 ] @=> int dchord[];
[ 88, 91, 95, 91 ] @=> int echord[];
[ 84, 88, 91, 88 ] @=> int cchord[];
[ 89, 93, 95, 93 ] @=> int fchord[];
[ 91, 95, 96, 95 ] @=> int gchord[];


[ 0, 0, 0, 0 ] @=> int currentChord[];



//Counter
0 => int counter;
1 => int chordNumber;

// main loop
while( true )
{
    
    //Button
    if (BUTTON == 1)
    {
        spork ~ newNote();
        0.5::second => now;
    }
    
   //Mandolin Settings
    setChord(chordNumber);
    // pitch
    currentChord[counter] => int pitch;
    // set freq
    pitch => Std.mtof => mandy[n].freq;
    
    //Axis 2: (pull out) White Noise Generator
    if (gt.axis[2] > 0.02) {       
        // note
        gt.axis[2] / 2 => mandy[n].noteOn;
    }
    
    //Axis 3: (side to side)  controls echo amount  
      
    Math.pow((gt.axis[3] * 100), 2) => filty.freq;
    
    //Axis 4: (up and down) controls pitch randomization
    Std.fabs(gt.axis[4]) => wetrev.mix;
        
    //Axis 5: (pull out)
    
    if (gt.axis[5] > 0.01) {       
        Math.pow((gt.axis[5] * 2), 2) => gain1.gain;
        
    } else {
        0 => gain1.gain;
    } 
    
    //
    T - gt.axis[1]*135::ms => now;
    //100::ms => now;
    
    //to make sound bounce around using modular
    counter++;
    
    if (counter == 4)
    {
        0 => counter;
    }
    n++;
    CHANNELS %=> n;
}


//Setting Chord
fun void setChord(int chordNumber)
{
    for (int j; j < 4; j++) 
    {
        if (chordNumber == 1) 
        {
            achord[j] => currentChord[j];
        }
        if (chordNumber == 2) 
        {
            dchord[j] => currentChord[j];
        }
        if (chordNumber == 3) 
        {
            echord[j] => currentChord[j];
        }
        if (chordNumber == 4) 
        {
            cchord[j] => currentChord[j];
        }
        if (chordNumber == 5) 
        {
            fchord[j] => currentChord[j];
        }
        if (chordNumber == 6) 
        {
            gchord[j] => currentChord[j];
        }
    }
}
//New Note
fun void newNote() 
{
    [ 81, 83, 84, 86, 88, 89, 91, 93 ] @=> int aminor[];
    // choose freq
    for (int i; i < VOICES; i++) 
    {
        <<< aminor[0] >>>;
        aminor[Math.random2(0, 7)] => int freq => Std.mtof  => sharpy[i].freq;
        //60 => int freq => Std.mtof  => sharpy[i].freq;
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
                keymsg.which => chordNumber;
                
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
                1 => BUTTON;
                chordNumber++;
                if (chordNumber == 7)
                {
                    1 => chordNumber;
                }
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