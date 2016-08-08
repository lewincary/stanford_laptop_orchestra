//synthesis patch
SinOsc matt => dac;
//set freq - chucking the frequency of 440 to matt
440 => matt.freq;
//advance time
<<< "before:", now/second>>>;
2::second => now;
<<< "after:", now/second >>>;

