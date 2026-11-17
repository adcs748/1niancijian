(function (global) {
  'use strict';

  var state = {
    active: false,
    paused: false,
    items: [],
    index: 0,
    loop: true,
    interval: 1,
    limitMinutes: 0,
    label: '',
    startedAt: 0,
    stopAt: 0,
    utterance: null
  };

  var onChange = null;
  var gapTimer = null;
  var tickTimer = null;
  var limitTimer = null;

  function nativeTTS() {
    return !!(global.AndroidTTS && typeof global.AndroidTTS.speak === 'function');
  }

  function supported() {
    if (nativeTTS()) return true;
    return typeof global.speechSynthesis !== 'undefined' &&
      typeof global.SpeechSynthesisUtterance !== 'undefined';
  }

  function snapshot() {
    return {
      active: state.active,
      paused: state.paused,
      index: state.index,
      total: state.items.length,
      label: state.label,
      loop: state.loop,
      interval: state.interval,
      limitMinutes: state.limitMinutes,
      remainingMs: state.stopAt > 0 ? Math.max(0, state.stopAt - Date.now()) : 0
    };
  }

  function notify() {
    if (typeof onChange === 'function') onChange(snapshot());
  }

  function clearTimers() {
    clearTimeout(gapTimer);
    clearTimeout(limitTimer);
    clearInterval(tickTimer);
    gapTimer = null;
    limitTimer = null;
    tickTimer = null;
  }

  function configure(options) {
    if (!options) return;
    if (typeof options.loop === 'boolean') state.loop = options.loop;
    if (typeof options.interval === 'number' && options.interval > 0) state.interval = options.interval;
    if (typeof options.limitMinutes === 'number' && options.limitMinutes >= 0) state.limitMinutes = options.limitMinutes;
    notify();
  }

  function cancelSpeech() {
    if (nativeTTS()) {
      try { global.AndroidTTS.stop(); } catch (err) {}
      return;
    }
    try { global.speechSynthesis.cancel(); } catch (err) {}
  }

  function advance() {
    if (!state.active || state.paused) return;
    state.index += 1;
    notify();
    gapTimer = setTimeout(function () {
      if (state.active && !state.paused) speakCurrent();
    }, Math.max(0, state.interval * 1000));
  }

  function speakCurrent() {
    if (!state.active || state.paused) return;

    if (state.index >= state.items.length) {
      if (state.loop) {
        state.index = 0;
      } else {
        stop();
        return;
      }
    }

    var text = state.items[state.index];
    if (!text) {
      state.index += 1;
      speakCurrent();
      return;
    }

    if (nativeTTS()) {
      state.utterance = null;
      try {
        global.AndroidTTS.speak(String(text));
      } catch (err) {
        advance();
      }
      return;
    }

    var utterance = new global.SpeechSynthesisUtterance(text);
    utterance.lang = 'en-US';
    utterance.rate = 0.92;
    utterance.pitchMultiplier = 1;

    utterance.onend = advance;

    utterance.onerror = function () {
      if (!state.active || state.paused) return;
      state.index += 1;
      gapTimer = setTimeout(function () {
        if (state.active && !state.paused) speakCurrent();
      }, 400);
    };

    state.utterance = utterance;
    global.speechSynthesis.speak(utterance);
  }

  global.__nativeTTSDone = function () {
    advance();
  };

  function start(items, label, startIndex) {
    if (!supported()) return false;

    stop(true);

    var clean = (items || []).filter(function (item) {
      return item && String(item).trim();
    }).map(function (item) {
      return String(item);
    });

    if (!clean.length) return false;

    var start = typeof startIndex === 'number' ? Math.floor(startIndex) : 0;
    state.active = true;
    state.paused = false;
    state.items = clean;
    state.index = Math.min(Math.max(0, start), Math.max(0, clean.length - 1));
    state.label = label || '';
    state.startedAt = Date.now();
    state.stopAt = 0;

    cancelSpeech();

    if (state.limitMinutes > 0) {
      state.stopAt = Date.now() + state.limitMinutes * 60000;
      limitTimer = setTimeout(function () {
        stop();
      }, state.limitMinutes * 60000);
    }

    tickTimer = setInterval(notify, 1000);
    speakCurrent();
    notify();
    return true;
  }

  function pause() {
    if (!state.active || state.paused) return;
    state.paused = true;
    if (nativeTTS()) {
      try { global.AndroidTTS.stop(); } catch (err) {}
    } else {
      try { global.speechSynthesis.pause(); } catch (err) {}
    }
    notify();
  }

  function resume() {
    if (!state.active || !state.paused) return;
    state.paused = false;
    if (nativeTTS()) {
      speakCurrent();
    } else {
      try { global.speechSynthesis.resume(); } catch (err) {}
    }
    notify();
  }

  function stop(silent) {
    state.active = false;
    state.paused = false;
    clearTimers();

    cancelSpeech();

    state.utterance = null;
    state.items = [];
    state.index = 0;
    state.label = '';
    state.stopAt = 0;

    if (!silent) notify();
  }

  function setOnChange(callback) {
    onChange = callback;
    notify();
  }

  global.ECPlayer = {
    supported: supported,
    start: start,
    pause: pause,
    resume: resume,
    stop: stop,
    configure: configure,
    snapshot: snapshot,
    setOnChange: setOnChange,
    isActive: function () { return state.active; }
  };
})(window);