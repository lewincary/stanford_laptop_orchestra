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

// synthesis
//initial
StifKarp fish[CHANNELS];
NRev rev[CHANNELS];


//My own
NRev revToothy;
LPF filty;


PulseOsc toothy => revToothy => dac;
440 => toothy.freq;
0.01 => toothy.gain;

SinOsc tinny => revToothy => dac;
440 => tinny.freq;
0.01 => tinny.gain;

Noise witty => filty => revToothy => dac;

0.01 => witty.gain;

// loop
for( int i; i < CHANNELS; i++ )
{
    fish[i] => rev[i] => dac.chan(i+CHAN_OFFSET);
    //.5 => rev[i].gain;
    .1 => rev[i].mix;
}

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
    //Axis 0: 
    
    
    //Axis 1:
    float ctrlfreq;
    gt.axis[1] => filty.freq;
    
    
    
    
    
    
    
    
    
    
    //Reverb Control
    //Gets wetter with left
    //Gets louder with right
    // for loop i = 0 ... n
    //      gt.axis[5]*2 => rev[i].mix;
    //for (int i; i < CHANNELS; i++) {
    // gt.axis[5]*2 => rev[n].mix;
    //}    
    //Math.round(gt.axis[2]) => rev[0].gain;
    //Math.round(gt.axis[2]) => rev[1].gain;
    
    
    
    
    //Reverb
    gt.axis[5] * 5 => revToothy.mix;
    
    
    // pitch
    Math.random2(30,30+Math.round((gt.axis[4]+1)*16-8)$int)*2 + PITCH_OFFSET => float pitch;
    
    
    // sustain
    gt.axis[5] => fish[n].pickupPosition;
    // stretch
    gt.axis[0]*.5+.5 => fish[n].stretch;
    
    // set freq
    pitch => Std.mtof => toothy.freq;
    pitch + 7 => Std.mtof => tinny.freq;
    // note
    //gt.axis[2]*2 => fish[n].noteOn;
    
    gt.axis[2] => toothy.gain;
    gt.axis[2] => tinny.gain;
    // wait
    // T - gt.axis[1]*131::ms => now; //variable way of controlling playback speed
    100::ms => now;
    
    //to make sound bounce around using modular
    n++;
    CHANNELS %=> n;
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