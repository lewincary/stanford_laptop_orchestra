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

//===========================================================//



//Keyboard handling
//keyboard number selected
0 => int keyNum;
1 => int keyAsc;
1 => int choirMod;
1 => int revvyMod;
bowl1name => string currentSample;

//Bowl1 SndBuf
SndBuf bowl1 => Chorus choir => NRev revvy => dac;
me.sourceDir() + "bowl1.aif" => string bowl1name;
if( me.args() ) me.arg(0) => bowl1name;
0.5 => bowl1.gain;

//Bowl2 SndBuf
SndBuf bowl2 => choir => revvy => dac;
me.sourceDir() + "bowl2.aif" => string bowl2name;
if( me.args() ) me.arg(0) => bowl2name;
0.5 => bowl2.gain;

//Bowl3 SndBuf
SndBuf bowl3 => choir => revvy => dac;
me.sourceDir() + "bowl3.aif" => string bowl3name;
if( me.args() ) me.arg(0) => bowl3name;
0.5 => bowl3.gain;

//cricket SndBuf
SndBuf cricket => choir => revvy => dac;
me.sourceDir() + "cricket.aif" => string cricketname;
if( me.args() ) me.arg(0) => cricketname;
0.5 => cricket.gain;

//eagle SndBuf
SndBuf eagle => choir => revvy => dac;
me.sourceDir() + "eagle.aif" => string eaglename;
if( me.args() ) me.arg(0) => eaglename;
0.5 => eagle.gain;

//frog SndBuf
SndBuf frog => choir => revvy => dac;
me.sourceDir() + "frog.aif" => string frogname;
if( me.args() ) me.arg(0) => frogname;
0.5 => frog.gain;

//kookaburra SndBuf
SndBuf kookaburra => choir => revvy => dac;
me.sourceDir() + "kookaburra.aif" => string kookaburraname;
if( me.args() ) me.arg(0) => kookaburraname;
0.5 => kookaburra.gain;

//loon SndBuf
SndBuf loon => choir => revvy => dac;
me.sourceDir() + "loon.aif" => string loonname;
if( me.args() ) me.arg(0) => loonname;
0.5 => loon.gain;

//owl SndBuf
SndBuf owl => choir => revvy => dac;
me.sourceDir() + "owl.aif" => string owlname;
if( me.args() ) me.arg(0) => owlname;
0.5 => owl.gain;

//peacock SndBuf
SndBuf peacock => choir => revvy => dac;
me.sourceDir() + "peacock.aif" => string peacockname;
if( me.args() ) me.arg(0) => peacockname;
0.5 => peacock.gain;

//===========================================================//



fun void setChorusModulation(float modKey)
{
    //between 0-20
    //oscillate between 0 and 0.3 on chorus
    (modKey * 0.015) => choir.modDepth;
    (modKey * 0.025) => choir.modDepth;
}

fun void setReverbModulation(float modKey)
{
    //between 0-20
    //oscillate between 0 and 0.3 on chorus
    (modKey * 0.025) => revvy.mix;
    
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
                keymsg.ascii - 48 => keyNum;
                keymsg.ascii => keyAsc;
                
                if (keyAsc = (93) 
                {
                    // ]
                    choirMod++;
                    //sets max value at 20
                    if (choirdMod == 21)
                    {
                        choirdMod--;
                    }  
                }
                if (keyAsc = (91) 
                {
                    // [
                    choirMod--;
                    //sets min value at 0
                    if (choirdMod == 0)
                    {
                        choirdMod++;
                    }  
                }
                if (keyAsc = (62) 
                {
                    // >
                    revvyMod++;
                    //sets max value at 20
                    if (revvyMod == 21)
                    {
                        revvyMod--;
                    }  
                }
                if (keyAsc = (60) 
                {
                    // <
                    revvyMod--;
                    //sets min value at 0
                    if (revvyMod == 0)
                    {
                        revvyMod++;
                    }  
                }
                
                
                //Loading Samples
                
                if (keyNum ==1) bowl1name => currentSample;
                if (keyNum ==2) bowl2name => currentSample;
                if (keyNum ==3) bowl3name => currentSample;
                if (keyNum ==4) cricketname => currentSample;
                if (keyNum ==5) eaglename => currentSample;
                if (keyNum ==6) frogname => currentSample;
                if (keyNum ==7) kookaburraname => currentSample;
                if (keyNum ==8) loonname => currentSample;
                if (keyNum ==9) owlname => currentSample;
                if (keyNum ==10) peacockname => currentSample;
                <<< keyNum >>>;
            }
        }
    }
    
}

spork - computerKeyboard();
spork - setChorusModulation(choirMod);
spork - setReverbModulation(revvyMod);
