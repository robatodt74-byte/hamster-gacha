(() => {
  let context;
  const active = new Set();
  window.hamsterBridge = {
    load() { try { return localStorage.getItem('hamster-fever.collection.v1') || ''; } catch { return ''; } },
    save(value) { try { localStorage.setItem('hamster-fever.collection.v1', value); } catch { /* Collection remains available for this visit. */ } },
    play(kind) {
      try {
        const Audio = window.AudioContext || window.webkitAudioContext;
        if (!Audio) return;
        context ||= new Audio();
        context.resume().catch(() => {});
        const notes = kind === 'win' ? [523, 659, 784, 1047] : kind === 'reach' ? [440, 660, 880] : kind === 'push' ? [220, 440] : [520];
        notes.forEach((frequency, i) => {
          const osc = context.createOscillator(), gain = context.createGain();
          const at = context.currentTime + i * .11;
          osc.type = 'sine'; osc.frequency.value = frequency;
          gain.gain.setValueAtTime(0, at);
          gain.gain.linearRampToValueAtTime(.06, at + .015);
          gain.gain.exponentialRampToValueAtTime(.001, at + .2);
          osc.connect(gain).connect(context.destination);
          active.add(osc);
          osc.onended = () => { active.delete(osc); osc.disconnect(); gain.disconnect(); };
          osc.start(at); osc.stop(at + .22);
        });
      } catch { /* Visual feedback is always available. */ }
    },
    stop() { for (const osc of active) { try { osc.stop(); } catch {} } active.clear(); }
  };
  document.addEventListener('visibilitychange', () => { if (document.hidden) window.hamsterBridge.stop(); });
})();
