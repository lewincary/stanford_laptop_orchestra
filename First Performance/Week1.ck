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

Noise witty => LPF filty => revToothy => dac;
0.00 => witty.gain;
0.00 => filty.freq;

BlowBotl belly => Echo eco => NRev revvy => dac;
440 => belly.freq;
0 => eco.mix;
0.1 => revvy.mix;



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
    //Axis 0: (side to side) LPF Freq //pow keeps it positive and on an exponential scale
    Math.pow((gt.axis[0] * 100), 2) => filty.freq;
    
    //Axis 1: controls reverb (up and down  - absolute value)
    Std.fabs(gt.axis[1]) => revToothy.mix;
    
    //Axis 2: (pull out) White Noise Generator
    if (gt.axis[2] > 0.01) {       
    gt.axis[2] => witty.gain;
    } else {
    0 => witty.gain;
    }
    
    //Axis 3: (side to side)  controls echo amount 
    gt.axis[3] => eco.mix;
    
    
    //Axis 4: (up and down) controls pitch randomization
    
       // pitch
       Math.random2(30,30+Math.round((gt.axis[4]+1)*16-8)$int)*2 + PITCH_OFFSET => float pitch;
       pitch => Std.mtof => belly.freq;
    
    //Axis 5: (pull out)
    
    if (gt.axis[5] > 0.01) {       
        gt.axis[5] => belly.noteOn;
    } 
    
    
    
    
    
   
  
    // wait
    T - gt.axis[4]*131::ms => now; //variable way of controlling playback speed
    //100::ms => now;
    
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