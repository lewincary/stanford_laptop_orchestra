// osc port
6449 => int OSC_PORT;

StifKarp k => NRev r => dac;
.3 => r.mix;

// OSC
OscIn in;
OscMsg omsg;

// the port
OSC_PORT => in.port;
// the address to listen for
in.addAddress( "/slork/play" );


//======Gametrack====//
6 => int CHANNELS;
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
//======Gametrack done=======////






//=====CHORDS=======//
[ 61, 63, 66, 68, 70 ] @=> int pentaScale[];

fun void setNote(int note)
{
    pentaScale[note] => Std.mtof => k.freq;
}

// handle
fun void network()
{
    while(true)
    {
        // wait for incoming event
        in => now;
        
        // drain the message queue
        while( in.recv(omsg) )
        {
            if( omsg.address == "/slork/play" )
            {
                omsg.getFloat(0) => float pitch;
                omsg.getFloat(1) => float velocity;
                
                // log
                <<< "RECV pitch:", pitch, "velocity:", velocity >>>;
                
                // set pitch
                pitch => Std.mtof => k.freq;
                // pluck it
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
                velocity => k.noteOn;
                }   
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

// network
spork ~ network();
spork ~ gametrak();

// infinite time loop
while( true ) 1::second => now;





