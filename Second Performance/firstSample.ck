//Paramters for this instrument
//pitch shift via pentatonic scale
//k chord/tuning - comb filter
//chord - modulate a little bit, not a ton, like between 0 -0.3
//length, therefore must be relatively long sample, with the longest time it can play being the same as the minimum/fastest time of the change between laptop setup


//now find a two minute sample = bird song through comb filter will sound cool
//reverb + kschord amount


//remember to get someone to program different patterns

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

//============== setup start=======//
SndBuf buffy => PitShift shifty => Chorus choir => NRev revvy => dac;



//============== setup end=======//

//keyboard number selected
0 => int keyNum;
1 => int keyAsc;
1 => int choirMod;
1 => int revvyMod;


//=====CHORDS=======//
[ 61, 63, 66, 68, 70 ] @=> int pentaScale[];



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

fun void setPitch(int keyNum)
{
    //how to code a pitchShifter?
    //current pitch is 54 in midi numbers
    pentaScale[keyNum] + 12 => Std.mtof=> pitchy.pitch;
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
                
                
                <<< keyNum >>>;
            }
        }
    }
    
}

spork - computerKeyboard();
spork - setChorusModulation(choirMod);
spork - setReverbModulation(revvyMod);
spork - setPitch(keyNum);
