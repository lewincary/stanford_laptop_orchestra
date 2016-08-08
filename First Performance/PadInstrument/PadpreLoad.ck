//Voices
5 => int VOICES;

SawOsc sharpy[VOICES] => ADSR envelope1 => LPF filty => Chorus choir => NRev wetrev => dac;

SinOsc sinny[VOICES] => envelope1 => filty => choir => wetrev => dac;

ADSR envelope2 => filty;


//Sawtooth Settings
for (int i; i < VOICES; i++) 
{
    0.01 => sharpy[i].gain;
}

//Sin Settings
for (int i; i < VOICES; i++) 
{
    0.01 => sinny[i].gain;
}


//Sawtooth envelope
(3::second, 0::ms, .5, 4::second)  => envelope1.set;


//LPF settings
1000 => filty.freq;
(5::second, 5::second, .5, 5::second)  => envelope2.set;

//Chorus settings
0.5 => choir.mix;
4 => choir.modDepth;
//70 => Std.mtof => choir.modFreq;

//Reverb Settings
0.5 => wetrev.mix;





while( true )
{
    // choose freq
    for (int i; i < VOICES; i++) 
    {
        Math.random2( 60, 70 ) => float freq => Std.mtof  => sharpy[i].freq;
        freq - 12 => Std.mtof => sinny[i].freq;
    }
    
    
    //Math.random2( 50, 60 ) => Std.mtof => sharpy.freq;
    //58 => Std.mtof => sharpy.freq;
    // key on - start attack
    envelope1.keyOn();
    // advance time by 800 ms
    3.5::second => now;
    // key off - start release
    envelope1.keyOff();
    // advance time by 800 ms
    4::second => now;
}










