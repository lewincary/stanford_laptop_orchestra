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

//=========== pad setup ==========//
// pol rate
.01::second => dur poll_rate;


0.8 => float ARP_GAIN;
0.05 => float OSC_GAIN;

SawOsc a[CHANNELS];
TriOsc b[CHANNELS];
Noise n[CHANNELS];
LPF f[CHANNELS];
NRev d[CHANNELS];
Gain gain[CHANNELS];

ADSR ar;

Rhodey arp[CHANNELS];

SinOsc m[CHANNELS];
SinOsc c[CHANNELS];

ar.attackTime(5::second);
ar.decayTime(2::second);
ar.releaseTime(2::second);
ar.keyOff(1);

5 => int NNOTES;
float note[NNOTES];
float arpnote[4];


for( int i; i < CHANNELS; i++ )
{
    arp[i] => f[i] => d[i] => gain[i] =>dac.chan(i+CHAN_OFFSET);

    a[i] => f[i] => d[i] => ar => gain[i] => dac.chan(i+CHAN_OFFSET);
    b[i] => f[i] => d[i] => ar => gain[i] => dac.chan(i+CHAN_OFFSET);
    n[i] => f[i] => d[i] => ar => gain[i] => dac.chan(i+CHAN_OFFSET);
    //================== BASS ======================//
    m[i] => c[i] => gain[i] =>  dac;
    
    Std.mtof(24) => c[i].freq;
    
    //frequency of the modulator - right now set to twice carrier
    //to make it more harmonic 
    c[i].freq()*2 => m[i].freq;
    
    //can also set m.freq independently of carrier freq
    //Std.mtof(36) => m.freq; 
    
    //the higher this value, the richer the spectrum. Keep it low for 
    //warm bass
    10 => m[i].gain; 
    0.6 => c[i].gain; 
    //don't change
    2 => c[i].sync;
    //======================= BASS =========================//
    
    
    
    0.5 => f[i].gain;
    1000 => f[i].freq;
    
    0.5 => d[i].gain;
    .15 => d[i].mix;
    
    0.04 => n[i].gain;
    
    //note[0] => a[i].freq;
    OSC_GAIN => a[i].gain;
    //note[4] => b[i].freq;
    OSC_GAIN => b[i].gain;
    
    ARP_GAIN => arp[i].gain;
}
//=========== pad has been setup ==========//


// duration
150::ms => dur T;
// counter
int number;

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
        //spork ~ newNote();
        //0.5::second => now;
    }
    
    
    
    
    //Axis 3: (side to side)  controls LPF
    for (int i; i < CHANNELS; i++)
    {    
    Math.pow((gt.axis[3] * 100), 2) => f[i].freq;
    10000 => f[i].freq;
    //Axis 5: (pull out) Turns on sound
    if (gt.axis[5] > 0.01) {       
        Math.pow((gt.axis[5] * 2), 2) => gain[i].gain;
    } else {
        0 => gain[i].gain;
    } 
    }
    //Triggers Note
    playNote(60);
    
    
    //to make sound bounce around using modular
    counter++;
    
    if (counter == 4)
    {
        0 => counter;
    }
    number++;
    CHANNELS %=> number;
}

//Play a note
fun void playNote(float note)
{
    note => Std.mtof => float freq;
    for( int i; i < CHANNELS; i++ )
    {
        freq => a[i].freq;
        note + 7 => Std.mtof => b[i].freq;
        note - 36 => Std.mtof => c[i].freq;
        c[i].freq()*2 => m[i].freq;
    }
    10::ms => now;
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