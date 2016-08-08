//================== BASS ======================//
SinOsc m => SinOsc c => Pan2 p => Gain g => dac; 
Std.mtof(24) => c.freq;

//frequency of the modulator - right now set to twice carrier
//to make it more harmonic 
c.freq()*2 => m.freq;

//can also set m.freq independently of carrier freq
//Std.mtof(36) => m.freq; 

//the higher this value, the richer the spectrum. Keep it low for 
//warm bass
10 => m.gain; 

//don't change
2 => c.sync;


while(true)
{   // modulate the pan
    Math.sin( now / 5::second * 2 * pi ) => p.pan;
    // advance time
    10::ms => now;
}
