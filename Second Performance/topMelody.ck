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



//===========================Setup===========================//

// synthesis
StifKarp fish[CHANNELS];
NRev rev[CHANNELS];
SawOsc a[CHANNELS];
TriOsc b[CHANNELS];
PulseOsc pulse[CHANNELS];
Gain gain[CHANNELS];

// loop
for( int i; i < CHANNELS; i++ )
{
    fish[i] => rev[i] => gain[i] => dac.chan(i+CHAN_OFFSET);
    a[i] => rev[i] => gain[i] => dac.chan(i+CHAN_OFFSET);
    b[i] => rev[i] => gain[i] => dac.chan(i+CHAN_OFFSET);
    pulse[i] => rev[i] => gain[i] => dac.chan(i+CHAN_OFFSET);
    //.5 => rev[i].gain;
    .1 => rev[i].mix;
}



//===========================Setup Complete===========================//



//Variables
0 => int currentArp;
0 => int counter;

//Scales
[ 81, 83, 84, 86, 88, 89, 91, 93 ] @=> int aminor[];
[ 81, 84, 88, 84 ] @=> int achord[];
[ 86, 89, 93, 89 ] @=> int dchord[];
[ 88, 91, 95, 91 ] @=> int echord[];
[ 84, 88, 91, 88 ] @=> int cchord[];
[ 89, 93, 95, 93 ] @=> int fchord[];
[ 91, 95, 96, 95 ] @=> int gchord[];
[ 0, 0, 0, 0 ] @=> int currentChord[];

// duration
150::ms => dur T;
// counter
int n;

// spork control
spork ~ gametrak();
// print
spork ~ print();

// global
0 => float PITCH_OFFSET;

// main loop
while( true )
{
    for (int i; i < CHANNELS; i++)
    {
        //Right hand
        if (gt.axis[5] > 0.01) {       
            Math.pow((gt.axis[5] * 2), 2) => gain[i].gain;
        } else {
            0 => gain[i].gain;
        }
        Std.fabs(gt.axis[3]) => rev[i].mix;
        
        //Left Hand
        if (gt.axis[1] < -0.5) {
            1 => currentArp;
        }
        if (gt.axis[1] > -0.5 && gt.axis[1] < 0) {
            2 => currentArp;
        }
        if (gt.axis[1] > 0 && gt.axis[1] < 0.5) {
            3 => currentArp;
        }
        if (gt.axis[1] > 0.5) {
            4 => currentArp;
        }
        Math.round(gt.axis[0]*12)*2 => PITCH_OFFSET;
        setChord(currentArp);
        playNote(currentChord[counter]);
    }
    
    // Right hand timing
    T - gt.axis[4]*135::ms => now;
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
    }
}

//Play a note
fun void playNote(float note)
{
    note => Std.mtof => float freq;
    note + 7 => Std.mtof => float freq2;
    note + 5 => Std.mtof => float freq3;
    for( int i; i < CHANNELS; i++ )
    {
        freq + PITCH_OFFSET => a[i].freq;
        freq2 + PITCH_OFFSET => b[i].freq;
        freq3 + PITCH_OFFSET => pulse[i].freq;
    }
    20::ms => now;
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