// osc port
6449 => int OSC_PORT;

StifKarp k => NRev r => dac;
.1 => r.mix;

// OSC
OscIn in;
OscMsg omsg;

// the port
OSC_PORT => in.port;
// the address to listen for
in.addAddress( "/slork/play" );

//Kick SndBuf
SndBuf birdSong => dac;
me.sourceDir() + "songOfBird.wav" => string birdname;
if( me.args() ) me.arg(0) => birdname;
0.5 => birdSong.gain;


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
                omsg.getInt(0) => int shouldMute;
                
                //mute/unmute handling
                if(shouldMute) 0 => birdSong.gain;
                else 1 => birdSong.gain;
                
            }
        }
    }
}

// network
spork ~ network();

// infinite time loop
while( true ) 1::second => now;





