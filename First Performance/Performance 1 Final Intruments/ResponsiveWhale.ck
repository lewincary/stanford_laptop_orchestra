// name: karptrak.ck
// desc: gametrak + stifkarp example
//
// author: Ge Wang (ge@ccrma.stanford.edu)
// date: spring 2014
//
// note: this is currently configured for 6 channels;
//       may need to do some wranglin' to make it work on stereo



// z axis deadzone
0 => float DEADZONE;
//Initialise Button
0 => int BUTTON;
2 => int CHANNELS;

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


//=========== pad setup ==========//
//Voices
2 => int VOICES;

SawOsc sharpy[VOICES];
LPF filty[VOICES];
Chorus choir[VOICES];
NRev wetrev[VOICES]; 
Gain gain1[VOICES];
SinOsc sinny[VOICES];

//Sawtooth Settings
for (int i; i < VOICES; i++) 
{
    sharpy[i] => filty[i] => choir[i] => wetrev[i] => gain1[i] => dac.chan(i);
    sinny[i] => filty[i] => choir[i] => wetrev[i] => gain1[i] => dac.chan(i);
    
    0.5 => filty[i].gain;
    1000 => filty[i].freq;
    
    //Chorus settings
    0.5 => choir[i].mix;
    4 => choir[i].modDepth;
    //70 => Std.mtof => choir.modFreq;

    //Reverb Settings
    0.5 => wetrev[i].mix;

    //Final Gain settings
    0.08 => sharpy[i].gain;
    0.08 => sinny[i].gain;
    0.1 => gain1[i].gain;
}



//Sawtooth envelope
//(3::second, 3::second, .5, 4::second)  => envelope1.set;


//LPF settings
//1000 => filty.freq;
//(5::second, 5::second, .5, 5::second)  => envelope2.set;



//=========== pad has been setup ==========//


// duration
150::ms => dur T;


// spork control
spork ~ gametrak();
spork ~ computerKeyboard();
//Keyboard

// print
// spork ~ print();


1 => int chordNumber;
70 => int midiNumber;
1 => int chordBank;
1 => int noteNumber;


// main loop
while( true )
{
    
    
    for (int i; i < VOICES; i++)
    {
        if (gt.axis[5] > 0.01) {       
            Math.pow((gt.axis[5] * 2), 2) => gain1[i].gain;
        } else {
            0 => gain1[i].gain;
        }
        Math.pow((gt.axis[3] * 20), 2) => filty[i].freq;
        Std.fabs(gt.axis[4]) => wetrev[i].mix;
    } 
    playNote(noteNumber);   
}




//Play a note
fun void playNote(int number)
{
    [ 81, 83, 84, 86, 88, 89, 91, 93 ] @=> int aminor[];
    aminor[number] => int freq;
    for( int i; i < VOICES; i++ )
    {
        <<< aminor[0] >>>;
        freq => Std.mtof  => sharpy[i].freq;
        freq - 12 => Std.mtof => sinny[i].freq;    
    }
    10::ms => now;
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
                keymsg.ascii - 48 => chordBank;
                <<< chordBank >>>;
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
                noteNumber++;
                if (noteNumber == 5)
                {
                    1 => noteNumber;
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