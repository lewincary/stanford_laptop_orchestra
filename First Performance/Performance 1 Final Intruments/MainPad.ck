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
// pol rate
.01::second => dur poll_rate;
2 => int CHANNELS;
0 => int CHAN_OFFSET;

0.8 => float ARP_GAIN;
0.05 => float OSC_GAIN;

SawOsc a[CHANNELS];
TriOsc b[CHANNELS];
PulseOsc pulse[CHANNELS];
TriOsc tri[CHANNELS];
Noise n[CHANNELS];
LPF f[CHANNELS];
NRev d[CHANNELS];

ADSR ar;

Rhodey arp[CHANNELS];

SinOsc m[CHANNELS];
SinOsc c[CHANNELS];
LPF filty[CHANNELS];

Gain gain[CHANNELS];
Gain gain2[CHANNELS];

Chorus choir[CHANNELS];

ar.attackTime(5::second);
ar.decayTime(2::second);
ar.releaseTime(2::second);
ar.keyOff(1);

5 => int NNOTES;
float note[NNOTES];
float arpnote[4];


for( int i; i < CHANNELS; i++ )
{
    arp[i] => f[i] => d[i] => gain[i] => dac.chan(i+CHAN_OFFSET);
    pulse[i] => f[i] => d[i] => ar => gain[i] => dac.chan(i+CHAN_OFFSET);
    tri[i] => f[i] => d[i] => ar => gain[i] => dac.chan(i+CHAN_OFFSET);
    a[i] => f[i] => d[i] => ar => gain[i] => dac.chan(i+CHAN_OFFSET);
    b[i] => f[i] => d[i] => ar => gain[i] =>dac.chan(i+CHAN_OFFSET);
    n[i] => f[i] => d[i] => ar => gain[i] =>dac.chan(i+CHAN_OFFSET);
    //================== BASS ======================//
    m[i] => c[i] => filty[i] => gain2[i] =>  dac;
    
    Std.mtof(24) => c[i].freq;
    
    //frequency of the modulator - right now set to twice carrier
    //to make it more harmonic 
    c[i].freq()*2 => m[i].freq;
    
    //can also set m.freq independently of carrier freq
    //Std.mtof(36) => m.freq; 
   
    //the higher this value, the richer the spectrum. Keep it low for 
    //warm bass
    10 => m[i].gain; 
    0.2 => c[i].gain; 
    //don't change
    2 => c[i].sync;
    //======================= BASS =========================//
    
    
    
    0.5 => f[i].gain;
    1000 => f[i].freq;
    
    0.5 => d[i].gain;
    .2 => d[i].mix;
    
    0.04 => n[i].gain;
    
    //note[0] => a[i].freq;
    OSC_GAIN => a[i].gain;
    //note[4] => b[i].freq;
    OSC_GAIN => b[i].gain;
    OSC_GAIN => pulse[i].gain;
    OSC_GAIN => tri[i].gain;
    ARP_GAIN => arp[i].gain;
    
    //0.4 => gain[i].gain;
}


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

//=====CHORDS=======//
[ 81, 83, 84, 86, 88, 89, 91, 93 ] @=> int aminor[];
[ 81, 84, 88, 93 ] @=> int achord[]; //1
[ 88, 91, 95, 100 ] @=> int echord[]; //2
[ 86, 89, 93, 98 ] @=> int dchord[]; //3
[ 84, 88, 91, 96 ] @=> int cchord[]; //4
[ 84, 88, 91, 96 ] @=> int c2chord[];//5
[ 79, 83, 84, 91 ] @=> int gchord[]; //6
[ 81, 84, 88, 93 ] @=> int a2chord[]; //7
[ 77, 81, 84, 89 ] @=> int fchord[]; //8


[ 0, 0, 0, 0 ] @=> int currentChord[];

// main loop
while( true )
{
    for (int i; i < CHANNELS; i++)
    {
        if (gt.axis[5] > 0.01) {       
            Math.pow((gt.axis[5] * 2), 2) => gain[i].gain;
        } else {
            0 => gain[i].gain;
        }
        if (gt.axis[2] > 0.01) {       
            Math.pow((gt.axis[2] * 2), 2) => gain2[i].gain;
        } else {
            0 => gain2[i].gain;
        }
        Math.pow((gt.axis[3] * 100), 2) => f[i].freq;
        Math.pow((gt.axis[0] * 20), 2) => filty[i].freq;
    } 
    setChord(chordNumber, chordBank);
    playNote(currentChord);
}

//Setting Chord
fun void setChord(int chordNumber, int chordBank)
{
    for (int j; j < 4; j++) 
    {
        if (chordBank == 1)
        {
            if (chordNumber == 1) 
            {
                70 => midiNumber;
                achord[j] => currentChord[j];
            }
            if (chordNumber == 2) 
            {
                71 => midiNumber;
                echord[j] => currentChord[j];
            }
            if (chordNumber == 3) 
            {
                72 => midiNumber;
                dchord[j] => currentChord[j];
            }
            if (chordNumber == 4) 
            {
                73 => midiNumber;
                cchord[j] => currentChord[j];
            }  
        }
        if (chordBank == 2)
        {
            if (chordNumber == 1) 
            {
                74 => midiNumber;
                cchord[j] => currentChord[j];
            }
            if (chordNumber == 2) 
            {
                75 => midiNumber;
                gchord[j] => currentChord[j];
            }
            if (chordNumber == 3) 
            {
                75 => midiNumber;
                achord[j] => currentChord[j];
            }
            if (chordNumber == 4) 
            {
                75 => midiNumber;
                fchord[j] => currentChord[j];
            }   
        }
    }
}


//Play a note
fun void playNote(int note[])
{
    //note => Std.mtof => float freq;
    for( int i; i < CHANNELS; i++ )
    {
        for (int j; j < 4; j++)
        {
            if (j == 0)
            {
                note[j] => Std.mtof => a[i].freq;
                note[j] - 36 => Std.mtof => c[i].freq;
                c[i].freq()*2 => m[i].freq;
            }
            if (j == 1)
            {
                note[j] => Std.mtof => b[i].freq;
            }
            if (j == 2)
            {
                note[j] - 12  => Std.mtof => tri[i].freq;
            }
            if (j == 3)
            {
                note[j] - 24 => Std.mtof => pulse[i].freq;
            }
        }
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
                chordNumber++;
                if (chordNumber == 5)
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