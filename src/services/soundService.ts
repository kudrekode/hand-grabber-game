// Tiny synthesized arcade cues. No audio files, networking or external dependencies.
class SoundService {
  enabled=false;
  private context:AudioContext|undefined;
  unlock() {
    if(!this.enabled)return;
    try {this.context??=new AudioContext();void this.context.resume();}catch{}
  }
  private note(frequency:number,end:number,duration:number,volume:number,type:OscillatorType='sine',delay=0) {
    if(!this.enabled)return;
    this.unlock();const context=this.context;if(!context)return;
    const start=context.currentTime+delay,oscillator=context.createOscillator(),gain=context.createGain();
    oscillator.type=type;oscillator.frequency.setValueAtTime(frequency,start);oscillator.frequency.exponentialRampToValueAtTime(Math.max(20,end),start+duration);
    gain.gain.setValueAtTime(volume,start);gain.gain.exponentialRampToValueAtTime(.001,start+duration);
    oscillator.connect(gain);gain.connect(context.destination);oscillator.start(start);oscillator.stop(start+duration);
  }
  private noise(duration:number,volume:number,frequency:number) {
    if(!this.enabled)return;
    this.unlock();const context=this.context;if(!context)return;
    const buffer=context.createBuffer(1,Math.ceil(context.sampleRate*duration),context.sampleRate),data=buffer.getChannelData(0);
    for(let i=0;i<data.length;i++)data[i]=(Math.random()*2-1)*(1-i/data.length)**2;
    const source=context.createBufferSource(),filter=context.createBiquadFilter(),gain=context.createGain();
    source.buffer=buffer;filter.type='lowpass';filter.frequency.value=frequency;gain.gain.value=volume;
    source.connect(filter);filter.connect(gain);gain.connect(context.destination);source.start();
  }
  crush(size:number) {
    if(size<22){this.note(620,210,.085,.075,'triangle');this.noise(.035,.045,2600);}
    else if(size<70){this.note(230,65,.16,.11,'triangle');this.noise(.13,.07,1600);}
    else {const major=size>=180;this.note(major?78:115,28,major?.3:.22,.16);this.note(710,210,.08,.03,'triangle');this.noise(major?.22:.15,.11,800);}
  }
  gate(positive:boolean) {
    if(positive){for(const [i,f] of [480,720,960].entries())this.note(f,f*.95,.1,.055,'triangle',i*.05);}
    else {this.note(330,110,.2,.07,'sawtooth');this.noise(.1,.03,1000);}
  }
  coin(){this.note(1100,1600,.065,.035,'sine');this.note(1650,1950,.06,.02,'sine',.045);}
  fail(){this.note(130,28,.35,.15,'sawtooth');this.noise(.2,.13,1200);}
  whoosh(){this.noise(.11,.025,3200);}
  highScore(){for(const [i,f] of [520,650,780,1040].entries())this.note(f,f,.16,.045,'triangle',.17+i*.085);}
  purchase(){this.note(650,980,.12,.05,'triangle');}
}
export const soundService=new SoundService();
