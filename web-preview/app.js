(function () {
  'use strict';

  /* ==================== 基础工具 ==================== */

  var viewport = document.getElementById('viewport');
  var phone = document.getElementById('phone');

  function $id(id) {
    return document.getElementById(id);
  }

  function esc(value) {
    var entities = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
    return String(value == null ? '' : value).replace(/[&<>"']/g, function (ch) {
      return entities[ch];
    });
  }

  function uid() {
    return 'a' + Math.random().toString(36).slice(2, 8) + Date.now().toString(36);
  }

  function loadJSON(key, fallback) {
    try {
      var raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (err) {
      return fallback;
    }
  }

  function saveJSON(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch (err) {}
  }

  function truncate(text, max) {
    var value = String(text == null ? '' : text);
    return value.length > max ? value.slice(0, max) + '…' : value;
  }

  var ICONS = {
    doc: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><path d="M9 13h6M9 17h4"/>',
    docPlus: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/><path d="M12 11v5M9.5 13.5h5"/>',
    arrowUpRight: '<path d="M7 17 17 7"/><path d="M9 7h8v8"/>',
    chevronRight: '<path d="m9 18 6-6-6-6"/>',
    chevronLeft: '<path d="m15 18-6-6 6-6"/>',
    speaker: '<path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.6a5 5 0 0 1 0 6.8"/><path d="M18.4 5.7a9 9 0 0 1 0 12.6"/>',
    star: '<path d="m12 3 2.7 5.7 6.3.9-4.5 4.4 1.1 6.2L12 17.3 6.4 20.2l1.1-6.2L3 9.6l6.3-.9z"/>',
    starOff: '<path d="m12 3 2.7 5.7 6.3.9-4.5 4.4 1.1 6.2L12 17.3 6.4 20.2l1.1-6.2L3 9.6l6.3-.9z"/><path d="m4 4 16 16"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m20.5 20.5-4.4-4.4"/>',
    translate: '<path d="M4 5h7M7.5 5v2c0 3.4-2 5.7-4.5 6.8"/><path d="M5 9.5c.8 2.4 2.6 4.1 4.8 5.1"/><path d="m13 20 3.8-9.6L20.6 20"/><path d="M14.4 16.6h4.8"/>',
    more: '<circle cx="5.5" cy="12" r="1.4" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none"/><circle cx="18.5" cy="12" r="1.4" fill="currentColor" stroke="none"/>',
    refresh: '<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/>',
    folder: '<path d="M3 7a2 2 0 0 1 2-2h4.5l2 2H19a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
    clipboard: '<rect x="8" y="2.5" width="8" height="4" rx="1.2"/><path d="M16 4.5h1.5A2.5 2.5 0 0 1 20 7v12.5a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 19.5V7a2.5 2.5 0 0 1 2.5-2.5H8"/>',
    close: '<path d="M18 6 6 18M6 6l12 12"/>',
    check: '<path d="M20 6 9 17l-5-5"/>',
    trash: '<path d="M3.5 6.5h17"/><path d="M8.5 6.5V4.5h7v2"/><path d="M18.5 6.5v13a2 2 0 0 1-2 2h-9a2 2 0 0 1-2-2v-13"/><path d="M10 11v6M14 11v6"/>',
    book: '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>',
    text: '<path d="M4 6h16M4 12h16M4 18h10"/>',
    moon: '<path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    eye: '<path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>',
    eyeOff: '<path d="M3 3l18 18"/><path d="M10.6 6.2A10.9 10.9 0 0 1 12 6c6.4 0 10 6 10 6a17 17 0 0 1-3 3.6"/><path d="M6.3 6.9C3.6 8.7 2 12 2 12s3.6 6 10 6c1.2 0 2.3-.2 3.3-.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
    play: '<path d="M7 4l13 8-13 8z"/>',
    pause: '<path d="M8 4v16M16 4v16"/>',
    stop: '<rect x="6" y="6" width="12" height="12" rx="2"/>',
    palette: '<path d="M12 3a9 9 0 1 0 0 18h1.5a2.5 2.5 0 0 0 0-5H12a2 2 0 0 1 0-4h4a4 4 0 0 0 0-8z"/><circle cx="7.5" cy="10.5" r="1.1" fill="currentColor" stroke="none"/><circle cx="10" cy="7" r="1.1" fill="currentColor" stroke="none"/><circle cx="14.5" cy="7" r="1.1" fill="currentColor" stroke="none"/>',
    photo: '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8.5" cy="10" r="1.5"/><path d="m21 15-5-5L5 19"/>',
    cloud: '<path d="M17.5 19H6a4 4 0 0 1-.6-7.9A6.5 6.5 0 0 1 18 9.6a4.7 4.7 0 0 1-.5 9.4z"/>',
    shield: '<path d="M12 3 4.5 6.5v5.4c0 4.7 3.2 8 7.5 9.1 4.3-1.1 7.5-4.4 7.5-9.1V6.5z"/><path d="m9 12 2 2 4-4"/>'
  };

  function icon(name, size) {
    var s = size || 20;
    return '<svg class="ico" width="' + s + '" height="' + s + '" viewBox="0 0 24 24" fill="none" ' +
      'stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
      (ICONS[name] || '') + '</svg>';
  }

  /* ==================== 词库 ==================== */

  var dictionary = { cet4: [], cet6: [], index: new Map() };

  function parseWords(raw, level) {
    if (!raw) return [];
    return raw.split(/\r?\n/).map(function (line) {
      return line.trim();
    }).filter(function (line) {
      return line && line.charAt(0) !== '#';
    }).map(function (line) {
      var parts = line.split('|').map(function (p) { return p.trim(); });
      var word = parts[0] || '';
      var phonetic = parts.length >= 3 ? parts[1] : '';
      var meaning = parts.length >= 3 ? parts[2] : (parts[1] || '');
      return { word: word, phonetic: phonetic, meaning: meaning, level: level };
    }).filter(function (entry) {
      return entry.word && entry.meaning;
    });
  }

  function initDictionary() {
    dictionary.cet4 = parseWords(window.EC_CET4, 'cet4');
    dictionary.cet6 = parseWords(window.EC_CET6, 'cet6');
    dictionary.index.clear();
    dictionary.cet4.concat(dictionary.cet6).forEach(function (entry) {
      var key = normalizeKey(entry.word);
      if (!dictionary.index.has(key)) dictionary.index.set(key, []);
      dictionary.index.get(key).push(entry);
    });
  }

  function normalizeKey(word) {
    return String(word == null ? '' : word)
      .toLowerCase()
      .replace(/’/g, "'")
      .replace(/^'+|'+$/g, '');
  }

  function baseForms(word) {
    var value = word.toLowerCase();
    var out = [];
    var seen = {};
    function add(candidate) {
      if (candidate && candidate.length > 1 && candidate !== value && !seen[candidate]) {
        seen[candidate] = true;
        out.push(candidate);
      }
    }
    if (/['’]s$/.test(value)) add(value.slice(0, -2));
    if (/ies$/.test(value) && value.length > 3) add(value.slice(0, -3) + 'y');
    if (/es$/.test(value) && value.length > 2) add(value.slice(0, -2));
    if (/s$/.test(value) && !/ss$/.test(value) && value.length > 2) add(value.slice(0, -1));
    if (/ed$/.test(value) && value.length > 3) {
      add(value.slice(0, -2));
      add(value.slice(0, -1));
    }
    if (/ing$/.test(value) && value.length > 4) {
      add(value.slice(0, -3));
      add(value.slice(0, -3) + 'e');
    }
    if (/ly$/.test(value) && value.length > 3) add(value.slice(0, -2));
    return out;
  }

  function findEntries(word) {
    var key = normalizeKey(word);
    if (dictionary.index.has(key)) return dictionary.index.get(key);
    var forms = baseForms(key);
    for (var i = 0; i < forms.length; i += 1) {
      if (dictionary.index.has(forms[i])) return dictionary.index.get(forms[i]);
    }
    return [];
  }

  function levelLabel(level) {
    return level === 'cet4' ? 'CET-4' : 'CET-6';
  }

  function isVerbWord(word) {
    var entries = findEntries(word);
    for (var i = 0; i < entries.length; i += 1) {
      if (/(^|\s)v\./.test(entries[i].meaning)) return true;
    }
    return false;
  }

  /* ==================== 在线翻译 ==================== */

  var CACHE_KEY = 'englishcoach.web.cache.v1';
  var translationCache = loadJSON(CACHE_KEY, {});

  function saveCache() {
    var keys = Object.keys(translationCache);
    if (keys.length > 400) {
      var trimmed = {};
      keys.slice(-300).forEach(function (key) { trimmed[key] = translationCache[key]; });
      translationCache = trimmed;
    }
    saveJSON(CACHE_KEY, translationCache);
  }

  function fetchWithTimeout(url, timeout) {
    if (typeof AbortController === 'undefined') return fetch(url);
    var controller = new AbortController();
    var timer = setTimeout(function () { controller.abort(); }, timeout || 8000);
    return fetch(url, { signal: controller.signal }).then(function (response) {
      clearTimeout(timer);
      return response;
    }, function (error) {
      clearTimeout(timer);
      throw error;
    });
  }

  function googleTranslate(text) {
    var url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=zh-CN&dt=t&q=' +
      encodeURIComponent(text);
    return fetchWithTimeout(url).then(function (response) {
      if (!response.ok) throw new Error('google');
      return response.json();
    }).then(function (data) {
      if (!Array.isArray(data) || !Array.isArray(data[0])) throw new Error('google parse');
      var output = data[0].map(function (segment) {
        return Array.isArray(segment) ? String(segment[0] || '') : '';
      }).join('');
      if (!output) throw new Error('google empty');
      return output;
    });
  }

  function myMemoryTranslate(text) {
    var url = 'https://api.mymemory.translated.net/get?q=' +
      encodeURIComponent(text.slice(0, 480)) + '&langpair=en%7Czh-CN';
    return fetchWithTimeout(url).then(function (response) {
      if (!response.ok) throw new Error('mymemory');
      return response.json();
    }).then(function (data) {
      var output = data && data.responseData && data.responseData.translatedText;
      if (!output) throw new Error('mymemory parse');
      return decodeEntities(output);
    });
  }

  function decodeEntities(text) {
    return String(text)
      .replace(/&#39;/g, "'")
      .replace(/&quot;/g, '"')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>');
  }

  function translateOnline(text) {
    var trimmed = String(text || '').trim();
    if (!trimmed) return Promise.resolve('');
    if (translationCache[trimmed]) return Promise.resolve(translationCache[trimmed]);
    return googleTranslate(trimmed)
      .catch(function () { return myMemoryTranslate(trimmed); })
      .then(function (result) {
        var cleaned = String(result || '').trim();
        if (!cleaned) throw new Error('empty translation');
        translationCache[trimmed] = cleaned;
        saveCache();
        return cleaned;
      });
  }

  function offlineGloss(text) {
    var hits = 0;
    var output = String(text).split(/(\s+)/).map(function (token) {
      if (!token || /^\s+$/.test(token)) return token;
      var core = token.replace(/^[^A-Za-z]+|[^A-Za-z]+$/g, '');
      if (!core) return token;
      var entries = findEntries(core);
      if (!entries.length) return token;
      hits += 1;
      return '【' + entries[0].meaning.replace(/^[a-z]+\.\s*/i, '') + '】';
    }).join('');
    return hits >= 3 ? '（离线逐词示意）' + output : '';
  }

  function translateParagraph(text) {
    return translateOnline(text).catch(function () {
      var gloss = offlineGloss(text);
      if (gloss) return gloss;
      throw new Error('无法连接在线翻译服务（浏览器可能拦截了跨域请求）。请检查网络，或稍后重试。');
    });
  }

  function speak(text) {
    var content = String(text || '').trim();
    if (!content) return;
    if (!('speechSynthesis' in window)) {
      toast('当前浏览器不支持语音朗读');
      return;
    }
    if (window.ECPlayer && window.ECPlayer.isActive()) {
      window.ECPlayer.stop();
    }
    try {
      window.speechSynthesis.cancel();
      var utterance = new SpeechSynthesisUtterance(content.slice(0, 1200));
      utterance.lang = 'en-US';
      utterance.rate = 0.92;
      window.speechSynthesis.speak(utterance);
    } catch (err) {
      toast('语音朗读失败');
    }
  }

  /* ==================== 示例数据 ==================== */

  var SAMPLE_ARTICLES = [
    {
      id: 'sample-reading',
      title: 'The Value of Reading',
      createdAt: Date.now() - 86400000,
      content: 'Reading is one of the most rewarding habits a person can build. It opens a window to new ideas, distant places, and lives we would never otherwise know.\n\nWhen we read every day, even for just twenty minutes, our vocabulary grows and our ability to focus improves. Researchers have found that regular readers tend to be more empathetic, because stories let us experience the world through another person\'s eyes.\n\nIn a world full of short videos and endless notifications, reading asks us to slow down. That quiet attention is not a waste of time; it is a way of training the mind. The benefits may be invisible at first, but they accumulate over the years.',
      translations: {
        '0': '阅读是一个人能养成的最有价值的习惯之一。它为我们打开一扇窗，通向新的思想、遥远的地方，以及我们原本永远无法了解的人生。',
        '1': '当我们每天阅读，哪怕只有二十分钟，词汇量也会增长，专注力也会提高。研究人员发现，经常阅读的人往往更有同理心，因为故事让我们通过他人的眼睛去体验世界。',
        '2': '在一个充满短视频和无休止通知的世界里，阅读要求我们慢下来。这种安静的专注并不是浪费时间，而是一种训练心智的方式。益处或许一开始看不见，但会随着岁月积累。'
      },
      translatedAt: Date.now() - 86000000
    },
    {
      id: 'sample-sleep',
      title: 'Why Sleep Matters',
      createdAt: Date.now() - 43200000,
      content: 'Sleep is not simply a pause between one day and the next. While we sleep, the brain sorts through the experiences of the day, strengthening memories and clearing away waste.\n\nStudents often sacrifice sleep before exams, believing that more study time means better results. In fact, research shows the opposite: without enough rest, attention and memory both decline. A well-rested mind learns faster than a tired one.\n\nThe lesson is simple. Good sleep is not a luxury; it is part of the work itself.',
      translations: {
        '0': '睡眠并不只是今天与明天之间的一段停顿。当我们睡觉时，大脑会梳理白天的经历，巩固记忆、清除废物。',
        '1': '学生常常在考试前牺牲睡眠，认为更多的学习时间意味着更好的成绩。事实上，研究显示的正好相反：如果没有足够的休息，注意力和记忆力都会下降。休息充分的大脑比疲惫的大脑学得更快。',
        '2': '结论很简单。良好的睡眠不是奢侈品，它本身就是努力的一部分。'
      },
      translatedAt: Date.now() - 43000000
    }
  ];

  /* ==================== 真题题库数据 ==================== */

  var OFFICIAL_SOURCES = [
    {
      id: 'official-syllabus',
      title: '《全国大学英语四、六级考试大纲（2016 年修订版）》',
      tag: '官方大纲',
      description: '教育部教育考试院发布的官方考试大纲 PDF，包含考试性质、内容、题型与样题说明。',
      url: 'https://cet.neea.edu.cn/res/Home/1704/55b02330ac17274664f06d9d3db8249d.pdf',
      level: 'all'
    },
    {
      id: 'official-format',
      title: 'CET 笔试考核内容与试卷结构',
      tag: '官方说明',
      description: '四级 / 六级笔试试卷结构、题型、题量、分值比例与考试时间。',
      url: 'https://cet.neea.edu.cn/html1/folder/16113/1586-1.htm',
      level: 'all'
    },
    {
      id: 'official-home',
      title: '全国大学英语四、六级考试（CET）官方主页',
      tag: '官方入口',
      description: '考试动态、报名、成绩查询、常见问题等官方入口。',
      url: 'https://cet.neea.edu.cn/',
      level: 'all'
    },
    {
      id: 'official-score',
      title: 'CET 成绩查询',
      tag: '考试服务',
      description: '官方成绩查询入口。',
      url: 'https://cet.neea.edu.cn/cet/',
      level: 'all'
    }
  ];

  var BANK_SAMPLE_ARTICLES = [
    {
      id: 'bank-sample-convenience',
      title: 'The Hidden Cost of Convenience',
      createdAt: Date.now() - 100000000,
      bank: true,
      kind: 'sample',
      level: 'cet4',
      content: 'Online shopping has made life easier than ever. With a few taps, almost anything can arrive at our door within days. Yet this convenience carries costs that are easy to ignore when we are staring at a screen.\n\nEvery delivery involves packaging, fuel, and a journey across warehouses and roads. The cheap price on a product page rarely includes these hidden expenses. They are paid instead by the environment and, eventually, by all of us.\n\nNone of this means we should abandon online shopping. It means we should buy with more thought: combine orders, choose slower delivery when possible, and ask whether we truly need the item. Convenience is a tool, not an excuse.',
      translations: {
        '0': '网购让生活比以往更方便。轻点几下，几乎任何东西都能在几天内送到家门口。然而，这种便利背后有代价，只是当我们盯着屏幕时很容易忽略。',
        '1': '每一次配送都涉及包装、燃料，以及跨越仓库与道路的运输。商品页面上的低价很少包含这些隐性成本。它们由环境承担，最终也由我们所有人承担。',
        '2': '这并不意味着我们应该放弃网购，而是意味着我们应该更有思考地购买：合并订单、尽可能选择更慢的配送，并问自己是否真的需要这件商品。便利是一种工具，而不是借口。'
      },
      translatedAt: Date.now() - 99000000
    },
    {
      id: 'bank-sample-questions',
      title: 'Learning to Ask Better Questions',
      createdAt: Date.now() - 90000000,
      bank: true,
      kind: 'sample',
      level: 'cet4',
      content: 'Children ask questions constantly. Why is the sky blue? Why do people get sick? Their curiosity seems endless, and it is one of the most powerful learning tools they possess.\n\nAs we grow older, many of us stop asking. We worry about looking foolish, or we assume that the answer is already known. Over time, this silence makes our thinking narrower and our conversations duller.\n\nBetter questions do not require perfect knowledge. They require attention and honesty: What am I missing? Why do I believe this? Who might disagree, and why? A good question does not show weakness; it opens a door.',
      translations: {
        '0': '孩子们不停地提问。天空为什么是蓝的？人为什么会生病？他们的好奇心似乎无穷无尽，而这是他们拥有的最强大的学习工具之一。',
        '1': '随着年龄增长，我们中的许多人不再提问。我们担心显得愚蠢，或者假定答案早已知道。久而久之，这种沉默让我们的思维变得更窄，让我们的对话更无趣。',
        '2': '更好的问题并不需要完美的知识，而需要专注与诚实：我漏掉了什么？我为什么相信这一点？谁可能不同意，为什么？一个好问题并不会显得软弱，它会打开一扇门。'
      },
      translatedAt: Date.now() - 89000000
    },
    {
      id: 'bank-sample-silence',
      title: 'Why Cities Need Silence',
      createdAt: Date.now() - 80000000,
      bank: true,
      kind: 'sample',
      level: 'cet6',
      content: 'Modern cities are designed to be heard. Traffic roars, advertisements flash and music pours out of every shop. Noise is treated as a sign of energy, and quiet is often mistaken for emptiness.\n\nResearch tells a different story. Constant noise raises stress hormones, disturbs sleep, and makes concentration harder. The effects accumulate quietly, which is precisely why they are easy to dismiss.\n\nA city that protects quiet is not trying to silence its people. It is creating room for thought, rest, and conversation. Silence is not the absence of life; it is a condition that allows life to be noticed.',
      translations: {
        '0': '现代城市仿佛是为被听见而设计的。车流轰鸣，广告闪烁，音乐从每家店铺涌出。噪音被视为活力的标志，而安静常被误认为空洞。',
        '1': '研究却讲述了另一个故事。持续的噪音会升高压力激素、干扰睡眠，并让专注变得更难。这些影响悄无声息地累积，而这正是它们容易被忽视的原因。',
        '2': '保护安静的城市并不是要让人们沉默，而是在为思考、休息与交谈留出空间。安静并不是生命的缺席，而是让生命被察觉的条件。'
      },
      translatedAt: Date.now() - 79000000
    }
  ];

  function buildBankIndex() {
    var items = [];
    for (var year = 2026; year >= 2016; year -= 1) {
      var months = year === 2026 ? [6] : [6, 12];
      for (var m = 0; m < months.length; m += 1) {
        var month = months[m];
        var levels = ['cet4', 'cet6'];
        for (var l = 0; l < levels.length; l += 1) {
          for (var set = 1; set <= 3; set += 1) {
            items.push({
              id: 'paper-' + year + '-' + month + '-' + levels[l] + '-' + set,
              title: year + ' 年 ' + month + ' 月 ' + (levels[l] === 'cet4' ? 'CET-4' : 'CET-6') + ' 真题（第 ' + set + ' 套）',
              year: year,
              month: month,
              level: levels[l],
              set: set,
              type: 'index'
            });
          }
        }
      }
    }
    return items;
  }

  var BANK_INDEX = buildBankIndex();

  /* ==================== 状态 ==================== */

  var STORAGE_KEY = 'englishcoach.web.v1';

  function emptySelection() {
    return { mode: false, p: null, anchor: null, focus: null };
  }

  var state = {
    view: 'home',
    navStack: [],
    articleId: null,
    tab: 'cet4',
    search: '',
    showTranslations: true,
    fontSize: 17,
    theme: 'light',
    readMode: false,
    translating: false,
    progress: { done: 0, total: 0 },
    error: '',
    articles: [],
    favorites: [],
    dailyWord: null,
    selection: emptySelection(),
    playerSettings: { loop: true, interval: 1, limitMinutes: 0, pendingMode: 'words' },
    bankFilter: 'all',
    bankSection: 'all',
    importContext: 'article',
    backup: {
      settings: { url: '', token: '' },
      pending: [],
      records: [],
      uploading: false,
      progress: { done: 0, total: 0 },
      status: ''
    }
  };

  var currentWordResult = null;
  var wordRequestId = 0;
  var sheetOpen = false;
  var toastTimer = null;
  var selectionData = null;
  var selectionRequestId = 0;
  var selectionTimer = null;
  var pressState = null;
  var pressTimer = null;

  /* ==================== 安全备份 ==================== */

  var BACKUP_KEY = 'ec-backup-v1';

  function loadBackup() {
    var saved = loadJSON(BACKUP_KEY, null);
    if (!saved) return;
    if (saved.settings && typeof saved.settings === 'object') {
      state.backup.settings.url = saved.settings.url || '';
      state.backup.settings.token = saved.settings.token || '';
    }
    if (Array.isArray(saved.records)) {
      state.backup.records = saved.records;
    }
  }

  function persistBackup() {
    saveJSON(BACKUP_KEY, {
      settings: state.backup.settings,
      records: state.backup.records
    });
  }

  function backupTotalBytes(files) {
    return files.reduce(function (total, file) { return total + (file.size || 0); }, 0);
  }

  function formatBytes(bytes) {
    if (!bytes) return '0 B';
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / 1024 / 1024).toFixed(1) + ' MB';
  }

  /* ==================== 相册壁纸与组件图案 ==================== */

  var APPEARANCE_KEY = 'ec-appearance-v1';
  var appearance = {
    wallpaper: { image: '', opacity: 0.3 },
    skins: {},
    launch: { image: '', type: '', size: 60, fit: 'contain', duration: 2.2, enabled: true },
    icon: { type: 'builtin', style: 'blue', image: '' },
    editing: false
  };
  var pendingSkinKey = null;
  var pendingSkinLabel = '';
  var imageTarget = '';
  var launchTimer = null;

  function loadAppearance() {
    var saved = loadJSON(APPEARANCE_KEY, null);
    if (!saved) return;
    if (saved.wallpaper && typeof saved.wallpaper.image === 'string') {
      appearance.wallpaper.image = saved.wallpaper.image;
      appearance.wallpaper.opacity = typeof saved.wallpaper.opacity === 'number'
        ? Math.min(1, Math.max(0, saved.wallpaper.opacity))
        : 0.3;
    }
    if (saved.skins && typeof saved.skins === 'object') {
      appearance.skins = saved.skins;
    }
    if (saved.launch && typeof saved.launch === 'object') {
      appearance.launch = {
        image: typeof saved.launch.image === 'string' ? saved.launch.image : '',
        type: saved.launch.type || '',
        size: typeof saved.launch.size === 'number' ? saved.launch.size : 60,
        fit: saved.launch.fit === 'cover' ? 'cover' : 'contain',
        duration: typeof saved.launch.duration === 'number' ? saved.launch.duration : 2.2,
        enabled: saved.launch.enabled !== false
      };
    }
    if (saved.icon && typeof saved.icon === 'object') {
      appearance.icon = {
        type: saved.icon.type === 'custom' ? 'custom' : 'builtin',
        style: saved.icon.style || 'blue',
        image: typeof saved.icon.image === 'string' ? saved.icon.image : ''
      };
    }
  }

  function persistAppearance() {
    try {
      localStorage.setItem(APPEARANCE_KEY, JSON.stringify({
        wallpaper: appearance.wallpaper,
        skins: appearance.skins,
        launch: appearance.launch,
        icon: appearance.icon
      }));
    } catch (err) {
      toast('本地存储空间不足：图案未能保存，请换更小的图片或减少组件图案');
    }
  }

  function applyWallpaper() {
    var el = $id('wallpaper');
    if (!el) return;
    if (appearance.wallpaper.image) {
      el.style.backgroundImage = 'url("' + appearance.wallpaper.image + '")';
      el.style.opacity = String(appearance.wallpaper.opacity);
      el.classList.add('show');
    } else {
      el.style.backgroundImage = '';
      el.style.opacity = '0';
      el.classList.remove('show');
    }
  }

  function launchTypeLabel(type) {
    if (type === 'image/gif') return 'GIF（保留动画）';
    if (type === 'image/png') return 'PNG';
    if (type === 'image/jpeg') return 'JPG';
    return '未选择';
  }

  function renderLaunchMedia() {
    var media = $id('launchMedia');
    if (!media) return;
    if (appearance.launch.image) {
      media.innerHTML = '<img src="' + appearance.launch.image + '" alt="">';
    } else {
      media.innerHTML = '<div class="launch-brand">EnglishCoach<span>四六级英语</span></div>';
    }
  }

  function playLaunchScreen(force) {
    var screen = $id('launchScreen');
    if (!screen) return;
    var launch = appearance.launch;
    if (!force && !launch.enabled) return;

    renderLaunchMedia();
    screen.style.display = 'flex';
    screen.classList.remove('hide');
    screen.classList.toggle('cover', launch.fit === 'cover');

    var media = $id('launchMedia');
    if (media) {
      media.style.width = launch.fit === 'cover'
        ? '100%'
        : String(Math.min(100, Math.max(20, launch.size))) + '%';
    }

    var duration = Math.max(0.5, Number(launch.duration) || 2.2);
    clearTimeout(launchTimer);
    launchTimer = setTimeout(function () {
      screen.classList.add('hide');
      setTimeout(function () {
        screen.style.display = 'none';
        screen.classList.remove('hide');
      }, 480);
    }, duration * 1000);
  }

  function compressLaunchImage(file, type) {
    return new Promise(function (resolve, reject) {
      var reader = new FileReader();
      reader.onload = function () {
        var image = new Image();
        image.onload = function () {
          var scale = Math.min(1, 900 / Math.max(image.width, image.height));
          var canvas = document.createElement('canvas');
          canvas.width = Math.max(1, Math.round(image.width * scale));
          canvas.height = Math.max(1, Math.round(image.height * scale));
          var context = canvas.getContext('2d');
          if (type !== 'image/png') {
            context.fillStyle = '#ffffff';
            context.fillRect(0, 0, canvas.width, canvas.height);
          }
          context.drawImage(image, 0, 0, canvas.width, canvas.height);
          resolve(canvas.toDataURL(type === 'image/png' ? 'image/png' : 'image/jpeg', 0.85));
        };
        image.onerror = function () { reject(new Error('image load failed')); };
        image.src = String(reader.result || '');
      };
      reader.onerror = function () { reject(new Error('read failed')); };
      reader.readAsDataURL(file);
    });
  }

  function applyLaunchImage(dataUrl, type) {
    appearance.launch.image = dataUrl;
    appearance.launch.type = type;
    persistAppearance();
    toast('启动动画已更新（' + launchTypeLabel(type) + '）');
    if (sheetOpen && $id('launchSize')) reopenAppearanceSheet();
  }

  function normalizeLaunchType(file) {
    var type = String(file.type || '').toLowerCase();
    if (type === 'image/jpg') type = 'image/jpeg';
    if (type === 'image/jpeg' || type === 'image/png' || type === 'image/gif') return type;
    var name = String(file.name || '').toLowerCase();
    if (/\.gif$/.test(name)) return 'image/gif';
    if (/\.png$/.test(name)) return 'image/png';
    if (/\.(jpe?g)$/.test(name)) return 'image/jpeg';
    return '';
  }

  function handleLaunchFile(file) {
    if (!file) return;
    var type = normalizeLaunchType(file);
    if (!type) {
      toast('启动动画仅支持 JPG / PNG / GIF');
      return;
    }

    if (type === 'image/gif') {
      if (file.size > 1.5 * 1024 * 1024) {
        toast('GIF 超过 1.5MB，请压缩后再试');
        return;
      }
      var reader = new FileReader();
      reader.onload = function () {
        applyLaunchImage(String(reader.result || ''), type);
      };
      reader.onerror = function () { toast('GIF 读取失败'); };
      reader.readAsDataURL(file);
      return;
    }

    if (file.size > 12 * 1024 * 1024) {
      toast('图片过大（超过 12MB），请先压缩');
      return;
    }
    compressLaunchImage(file, type).then(function (dataUrl) {
      applyLaunchImage(dataUrl, type);
    }).catch(function () {
      toast('图片读取失败，请换一张试试');
    });
  }

  function appIconHtml(size, radius) {
    var icon = appearance.icon || { type: 'builtin', style: 'blue', image: '' };
    var px = size || 40;
    var radiusValue = radius || Math.round(px * 0.24);
    if (icon.type === 'custom' && icon.image) {
      return '<span class="app-icon" style="width:' + px + 'px;height:' + px + 'px;border-radius:' +
        radiusValue + 'px;background-image:url(\'' + icon.image + '\')"></span>';
    }
    var style = icon.style || 'blue';
    return '<span class="app-icon icon-' + style + '" style="width:' + px + 'px;height:' + px +
      'px;border-radius:' + radiusValue + 'px;font-size:' + Math.round(px * 0.5) + 'px">念</span>';
  }

  function iconOption(style, title) {
    var active = appearance.icon.type === 'builtin' && (appearance.icon.style || 'blue') === style;
    return '<button class="icon-option icon-' + style + (active ? ' active' : '') +
      '" data-action="set-icon-style" data-style="' + style + '" aria-label="' + esc(title) + '"></button>';
  }

  function setSkinAttribute(el, key, label) {
    if (!el) return;
    el.setAttribute('data-skin', key);
    el.setAttribute('data-skin-label', label);
  }

  function tagSkinTargets() {
    var view = viewport.querySelector('.view');
    if (!view) return;
    var i;

    if (state.view === 'home') {
      setSkinAttribute(view.querySelector('.import-card'), 'home-import', '导入卡片');
      setSkinAttribute(view.querySelector('.daily-card'), 'home-daily', '今日词汇');
      var levels = view.querySelectorAll('.level-card');
      for (i = 0; i < levels.length; i += 1) {
        setSkinAttribute(levels[i], i === 0 ? 'home-level-cet4' : 'home-level-cet6', i === 0 ? '四级词汇卡片' : '六级词汇卡片');
      }
      setSkinAttribute(view.querySelector('.wordbook-card'), 'home-favorites', '我的收藏');
      setSkinAttribute(view.querySelector('.bank-card'), 'home-bank', '真题题库');
      var articles = view.querySelectorAll('.article-row');
      for (i = 0; i < articles.length; i += 1) {
        setSkinAttribute(articles[i], 'article-' + articles[i].getAttribute('data-id'), '文章卡片');
      }
    } else if (state.view === 'reader') {
      var tools = view.querySelectorAll('.tool-btn');
      for (i = 0; i < tools.length; i += 1) {
        setSkinAttribute(tools[i], 'tool-' + (tools[i].getAttribute('data-action') || i), '阅读工具栏按钮');
      }
      var paras = view.querySelectorAll('.para-card');
      for (i = 0; i < paras.length; i += 1) {
        setSkinAttribute(paras[i], 'para-' + state.articleId + '-' + i, '阅读段落');
      }
      setSkinAttribute(view.querySelector('.translate-btn'), 'reader-translate', '翻译按钮');
    } else if (state.view === 'vocabulary') {
      var tabs = view.querySelectorAll('.seg');
      for (i = 0; i < tabs.length; i += 1) {
        setSkinAttribute(tabs[i], 'tab-' + (tabs[i].getAttribute('data-tab') || i), '词汇标签');
      }
      setSkinAttribute(view.querySelector('.searchbar'), 'vocab-search', '搜索栏');
      var mains = view.querySelectorAll('.vocab-main');
      for (i = 0; i < mains.length; i += 1) {
        var wordKey = mains[i].getAttribute('data-word');
        if (wordKey) setSkinAttribute(mains[i], 'word-' + wordKey, '词汇条目');
      }
      var favs = view.querySelectorAll('.fav-main');
      for (i = 0; i < favs.length; i += 1) {
        setSkinAttribute(favs[i], 'fav-' + (favs[i].getAttribute('data-id') || i), '收藏条目');
      }
    } else if (state.view === 'import') {
      setSkinAttribute(view.querySelector('.field'), 'import-title', '标题输入框');
      setSkinAttribute(view.querySelector('.import-textarea'), 'import-text', '正文输入框');
      var importBtns = view.querySelectorAll('.soft-btn');
      for (i = 0; i < importBtns.length; i += 1) {
        setSkinAttribute(importBtns[i], 'import-' + (importBtns[i].getAttribute('data-action') || i), '导入按钮');
      }
    } else if (state.view === 'bank') {
      var bankSegs = view.querySelectorAll('.seg');
      for (i = 0; i < bankSegs.length; i += 1) {
        setSkinAttribute(bankSegs[i], 'bank-seg-' + i, '题库筛选');
      }
      var bankRows = view.querySelectorAll('.bank-sample-card, .bank-official-row, .bank-paper-row');
      for (i = 0; i < bankRows.length; i += 1) {
        setSkinAttribute(bankRows[i], 'bank-' + (bankRows[i].getAttribute('data-id') || i), '题库条目');
      }
    }
  }

  function applySkins() {
    var nodes = viewport.querySelectorAll('[data-skin]');
    for (var i = 0; i < nodes.length; i += 1) {
      var node = nodes[i];
      var key = node.getAttribute('data-skin');
      var skin = appearance.skins[key];
      var layer = node.querySelector('.skin-layer');

      if (!skin || !skin.image) {
        if (layer && layer.parentNode) layer.parentNode.removeChild(layer);
        node.classList.remove('skin-target');
        continue;
      }

      node.classList.add('skin-target');
      if (!layer) {
        layer = document.createElement('span');
        layer.className = 'skin-layer';
        node.insertBefore(layer, node.firstChild);
      }
      layer.style.backgroundImage = 'url("' + skin.image + '")';
      layer.style.opacity = String(typeof skin.opacity === 'number' ? skin.opacity : 0.35);
    }
  }

  function updateSkinsFor(key) {
    var nodes = viewport.querySelectorAll('[data-skin]');
    for (var i = 0; i < nodes.length; i += 1) {
      if (nodes[i].getAttribute('data-skin') !== key) continue;
      var layer = nodes[i].querySelector('.skin-layer');
      var skin = appearance.skins[key];
      if (layer && skin) layer.style.opacity = String(skin.opacity);
    }
  }

  function compressImage(file, maxSize, quality) {
    return new Promise(function (resolve, reject) {
      var reader = new FileReader();
      reader.onload = function () {
        var image = new Image();
        image.onload = function () {
          var scale = Math.min(1, maxSize / Math.max(image.width, image.height));
          var canvas = document.createElement('canvas');
          canvas.width = Math.max(1, Math.round(image.width * scale));
          canvas.height = Math.max(1, Math.round(image.height * scale));
          var context = canvas.getContext('2d');
          context.fillStyle = '#ffffff';
          context.fillRect(0, 0, canvas.width, canvas.height);
          context.drawImage(image, 0, 0, canvas.width, canvas.height);
          resolve(canvas.toDataURL('image/jpeg', quality));
        };
        image.onerror = function () { reject(new Error('image load failed')); };
        image.src = String(reader.result || '');
      };
      reader.onerror = function () { reject(new Error('read failed')); };
      reader.readAsDataURL(file);
    });
  }

  function handleImageFile(file, target) {
    if (!file) return;
    var looksLikeImage = /^image\//.test(String(file.type || '')) ||
      /\.(jpe?g|png|gif|webp|bmp)$/i.test(String(file.name || ''));
    if (!looksLikeImage) {
      toast('请选择图片文件');
      return;
    }
    if (file.size > 12 * 1024 * 1024) {
      toast('图片过大（超过 12MB），请先裁剪或压缩');
      return;
    }
    var isWallpaper = target === 'wallpaper';
    compressImage(file, isWallpaper ? 1280 : 720, isWallpaper ? 0.8 : 0.72).then(function (dataUrl) {
      if (isWallpaper) {
        appearance.wallpaper.image = dataUrl;
        applyWallpaper();
        persistAppearance();
        toast('壁纸已更新');
        if (sheetOpen && $id('wallpaperOpacity')) reopenAppearanceSheet();
      } else {
        if (!appearance.skins[target] || !appearance.skins[target].opacity) {
          appearance.skins[target] = { image: dataUrl, opacity: 0.35 };
        } else {
          appearance.skins[target].image = dataUrl;
        }
        applySkins();
        persistAppearance();
        toast('组件图案已应用');
        if (sheetOpen && $id('skinOpacity')) reopenSkinSheet();
      }
    }).catch(function () {
      toast('图片读取失败，请换一张试试');
    });
  }

  function handleIconFile(file) {
    if (!file) return;
    var looksLikeImage = /^image\//.test(String(file.type || '')) ||
      /\.(jpe?g|png|gif|webp|bmp)$/i.test(String(file.name || ''));
    if (!looksLikeImage) {
      toast('请选择图片文件');
      return;
    }
    if (file.size > 8 * 1024 * 1024) {
      toast('图片过大（超过 8MB）');
      return;
    }
    compressImage(file, 720, 0.82).then(function (dataUrl) {
      appearance.icon = { type: 'custom', style: 'blue', image: dataUrl };
      persistAppearance();
      render();
      if (sheetOpen && $id('wallpaperOpacity')) openAppearanceSheet();
      toast('应用图标已更新');
    }).catch(function () {
      toast('图标读取失败，请换一张试试');
    });
  }

  var tesseractPromise = null;

  function loadTesseract() {
    if (window.Tesseract) return Promise.resolve(window.Tesseract);
    if (tesseractPromise) return tesseractPromise;
    tesseractPromise = new Promise(function (resolve, reject) {
      var script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.min.js';
      script.onload = function () {
        if (window.Tesseract) resolve(window.Tesseract);
        else reject(new Error('ocr load'));
      };
      script.onerror = function () {
        tesseractPromise = null;
        reject(new Error('ocr load'));
      };
      document.head.appendChild(script);
    });
    return tesseractPromise;
  }

  function setOcrStatus(text, progress) {
    var box = $id('ocrStatus');
    if (!box) return;
    if (!text) {
      box.hidden = true;
      box.innerHTML = '';
      return;
    }
    box.hidden = false;
    var bar = typeof progress === 'number'
      ? '<div class="ocr-bar"><span style="width:' +
        Math.round(Math.min(1, Math.max(0, progress)) * 100) + '%"></span></div>'
      : '';
    box.innerHTML = '<div>' + esc(text) + '</div>' + bar;
  }

  function cleanOcrText(text) {
    return String(text || '')
      .split(/\r?\n/)
      .map(function (line) { return line.trim(); })
      .filter(function (line) { return line && /[A-Za-z]/.test(line); })
      .join('\n')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  }

  function formatOcrStamp() {
    var now = new Date();
    var month = now.getMonth() + 1;
    var day = now.getDate();
    var hour = String(now.getHours()).padStart(2, '0');
    var minute = String(now.getMinutes()).padStart(2, '0');
    return month + '月' + day + '日 ' + hour + ':' + minute;
  }

  function handleOcrFile(file) {
    if (!file) return;
    if (!/^image\//.test(String(file.type || ''))) {
      toast('请选择图片文件');
      return;
    }
    if (file.size > 12 * 1024 * 1024) {
      toast('图片过大（超过 12MB）');
      return;
    }

    setOcrStatus('正在读取图片…', 0.05);
    var reader = new FileReader();
    reader.onload = function () {
      var dataUrl = String(reader.result || '');
      setOcrStatus('正在加载图片识别引擎（首次需要联网下载）…', 0.1);

      loadTesseract().then(function (Tesseract) {
        setOcrStatus('正在识别英文…', 0.2);
        return Tesseract.recognize(dataUrl, 'eng', {
          logger: function (message) {
            if (message && message.status === 'recognizing text') {
              setOcrStatus('正在识别英文…', 0.2 + (message.progress || 0) * 0.75);
            }
          }
        });
      }).then(function (result) {
        var raw = result && result.data && result.data.text ? String(result.data.text) : '';
        var cleaned = cleanOcrText(raw);
        if (!cleaned) {
          setOcrStatus('');
          toast('没有识别到英文内容，请换一张更清晰的图片');
          return;
        }

        var titleEl = $id('articleTitle');
        var contentEl = $id('articleContent');
        if (titleEl && !titleEl.value.trim()) {
          titleEl.value = '图片识别 · ' + formatOcrStamp();
        }
        if (contentEl) {
          contentEl.value = cleaned;
        }
        state.importContext = 'ocr';
        setOcrStatus('识别完成：已识别 ' + countWords(cleaned) + ' 个词，可直接开始阅读或继续编辑。', 1);
        toast('图片英文已识别，可检查后开始阅读');
      }).catch(function () {
        setOcrStatus('');
        toast('OCR 引擎加载失败，请检查网络，或改用「粘贴文本」');
      });
    };
    reader.onerror = function () {
      setOcrStatus('');
      toast('图片读取失败');
    };
    reader.readAsDataURL(file);
  }

  function downloadAppIcon() {
    var canvas = document.createElement('canvas');
    canvas.width = 1024;
    canvas.height = 1024;
    var ctx = canvas.getContext('2d');
    var icon = appearance.icon || { type: 'builtin', style: 'blue', image: '' };

    function finish() {
      canvas.toBlob(function (blob) {
        if (!blob) {
          toast('图标生成失败');
          return;
        }
        var url = URL.createObjectURL(blob);
        var link = document.createElement('a');
        link.href = url;
        link.download = '一念词间-图标-1024.png';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        setTimeout(function () { URL.revokeObjectURL(url); }, 1500);
        toast('图标已下载，可配合快捷指令设置到桌面');
      }, 'image/png');
    }

    if (icon.type === 'custom' && icon.image) {
      var image = new Image();
      image.onload = function () {
        var scale = Math.max(1024 / image.width, 1024 / image.height);
        var width = image.width * scale;
        var height = image.height * scale;
        ctx.drawImage(image, (1024 - width) / 2, (1024 - height) / 2, width, height);
        finish();
      };
      image.onerror = function () {
        ctx.fillStyle = '#3d6bf5';
        ctx.fillRect(0, 0, 1024, 1024);
        drawDefaultGlyph(ctx);
        finish();
      };
      image.src = icon.image;
      return;
    }

    var gradients = {
      blue: ['#3d6bf5', '#7a5cfa'],
      ink: ['#1c1c1e', '#4a4a52'],
      sunset: ['#ff7a59', '#ffb457'],
      forest: ['#1f8a70', '#63c98a']
    };
    var colors = gradients[icon.style] || gradients.blue;
    var gradient = ctx.createLinearGradient(0, 0, 1024, 1024);
    gradient.addColorStop(0, colors[0]);
    gradient.addColorStop(1, colors[1]);
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 1024, 1024);
    drawDefaultGlyph(ctx);
    finish();
  }

  function drawDefaultGlyph(ctx) {
    ctx.fillStyle = '#ffffff';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.font = 'bold 520px "PingFang SC", "Microsoft YaHei", Georgia, serif';
    ctx.fillText('念', 512, 540);
  }

  function openShortcutsGuide() {
    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="action-sheet">' +
        '<div class="action-title">设置自定义桌面图标</div>' +
        '<div class="bank-sheet-body">' +
          '<p class="tip" style="margin-top:0">1. 点击「下载 1024 图标」，把生成的 PNG 保存到相册或文件。</p>' +
          '<p class="tip">2. 打开 iPhone「快捷指令」App，新建一个「打开 App」快捷方式，选择「一念词间」。</p>' +
          '<p class="tip">3. 在快捷方式详情里点「添加到主屏幕」，选择第 1 步的图片作为图标。</p>' +
          '<p class="tip">4. 主屏幕会生成带自定义图标的入口；原 App 图标仍然保留。</p>' +
          '<p class="tip">说明：iOS 不允许 App 直接替换桌面图标，这是系统级限制；快捷指令是唯一能用任意相册图片作为桌面图标的官方方式。</p>' +
        '</div>' +
        '<button class="action-row" data-action="open-shortcuts-app">打开快捷指令</button>' +
        '<button class="action-row cancel" data-action="close-sheet">知道了</button>' +
      '</div>');
  }

  function exportPackage() {
    var includeArticles = $id('exportArticles') ? $id('exportArticles').checked : true;
    var includeFavorites = $id('exportFavorites') ? $id('exportFavorites').checked : true;
    var includeAppearance = $id('exportAppearance') ? $id('exportAppearance').checked : false;

    var payload = {
      app: '一念词间',
      packageVersion: 1,
      exportedAt: new Date().toISOString(),
      note: '由用户主动选择并导出的数据，不包含手机中的其他文件。'
    };

    if (includeArticles) {
      payload.articles = state.articles.map(function (article) {
        return {
          id: article.id,
          title: article.title,
          kind: article.kind || 'article',
          level: article.level || '',
          createdAt: article.createdAt,
          wordCount: countWords(article.content),
          paragraphCount: splitParagraphs(article.content).length,
          content: article.content,
          translations: article.translations || {}
        };
      });
    }

    if (includeFavorites) {
      payload.favorites = state.favorites;
    }

    if (includeAppearance) {
      payload.appearance = {
        wallpaperOpacity: appearance.wallpaper.opacity,
        launch: appearance.launch,
        icon: { type: appearance.icon.type, style: appearance.icon.style }
      };
    }

    var blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
    var url = URL.createObjectURL(blob);
    var link = document.createElement('a');
    var now = new Date();
    var stamp = now.getFullYear() + String(now.getMonth() + 1).padStart(2, '0') +
      String(now.getDate()).padStart(2, '0');
    link.href = url;
    link.download = '一念词间-数据包-' + stamp + '.json';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    setTimeout(function () { URL.revokeObjectURL(url); }, 1500);
    toast('数据包已生成，可用 viewer.html 查看');
  }

  function openAppearanceSheet() {
    var hasWallpaper = !!appearance.wallpaper.image;
    var percent = Math.round(appearance.wallpaper.opacity * 100);
    var launch = appearance.launch;
    var hasLaunch = !!launch.image;
    var launchSize = Math.round(launch.size);
    var launchTenth = Math.round(launch.duration * 10);
    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="sel-head"><div><div class="sel-title">外观与壁纸</div><div class="ws-phonetic">从相册选择，只保存在本机浏览器</div></div></div>' +
      '<div class="appearance-block">' +
        '<div class="appearance-label">主界面壁纸</div>' +
        '<div class="wallpaper-preview' + (hasWallpaper ? '' : ' empty') + '"' +
          (hasWallpaper ? ' style="background-image:url(\'' + appearance.wallpaper.image + '\')"' : '') + '>' +
          (hasWallpaper ? '' : '<span>尚未选择壁纸</span>') +
        '</div>' +
        '<div class="row-2">' +
          '<button class="soft-btn" data-action="pick-wallpaper">' + icon('folder', 15) + ' 从相册选择</button>' +
          '<button class="soft-btn" data-action="clear-wallpaper">移除壁纸</button>' +
        '</div>' +
        '<div class="slider-row"><span>透明度</span>' +
          '<input id="wallpaperOpacity" type="range" min="0" max="100" step="1" value="' + percent + '">' +
          '<span id="wallpaperOpacityValue">' + percent + '%</span></div>' +
      '</div>' +
      '<div class="appearance-block">' +
        '<div class="appearance-label">应用图标与桌面图标</div>' +
        '<div class="icon-preview-row">' +
          appIconHtml(64) +
          '<div class="tip" style="margin-top:0">选择内置样式或从相册选择图片，图标会用于首页与应用内展示。</div>' +
        '</div>' +
        '<div class="icon-style-row">' +
          iconOption('blue', '蓝色') + iconOption('ink', '墨黑') + iconOption('sunset', '日落') + iconOption('forest', '森林') +
        '</div>' +
        '<div class="row-2" style="margin-top:10px">' +
          '<button class="soft-btn" data-action="pick-icon">' + icon('folder', 15) + ' 从相册选择</button>' +
          '<button class="soft-btn" data-action="clear-icon">恢复默认</button>' +
        '</div>' +
        '<div class="desktop-preview">' +
          '<div class="desktop-icon-wrap">' + appIconHtml(64) + '<span>一念词间</span></div>' +
        '</div>' +
        '<div class="row-2" style="margin-top:10px">' +
          '<button class="soft-btn" data-action="download-icon">' + icon('folder', 15) + ' 下载 1024 图标</button>' +
          '<button class="soft-btn" data-action="open-shortcuts-guide">如何设置到桌面</button>' +
        '</div>' +
        '<div class="icon-note">iOS 不允许 App 直接用相册图片替换桌面图标。下载图标后，可用「快捷指令」新建“打开 App”快捷方式并添加到主屏幕，选择这张图片即可得到自定义桌面图标。</div>' +
      '</div>' +
      '<div class="appearance-block">' +
        '<div class="appearance-label">组件底层图案</div>' +
        '<div class="tip" style="margin-top:6px">进入编辑模式后，点击任意卡片、按钮或工具项，即可单独为它选择相册图片。</div>' +
        '<button class="translate-btn" style="margin-top:12px" data-action="start-skin-editing">' + icon('eye', 16) + ' 进入组件图案编辑</button>' +
      '</div>' +
      '<div class="appearance-block">' +
        '<div class="appearance-label">启动动画</div>' +
        '<div class="launch-preview' + (hasLaunch ? '' : ' empty') + '"' +
          (hasLaunch ? ' style="background-image:url(\'' + launch.image + '\')"' : '') + '>' +
          (hasLaunch ? '' : '<span>默认品牌动画</span>') +
        '</div>' +
        '<div class="launch-meta">当前格式：' + esc(launchTypeLabel(launch.type)) + ' · 支持 JPG / PNG / GIF</div>' +
        '<div class="row-2">' +
          '<button class="soft-btn" data-action="pick-launch">' + icon('folder', 15) + ' 选择图片</button>' +
          '<button class="soft-btn" data-action="clear-launch">清除动画</button>' +
        '</div>' +
        '<div class="slider-row"><span>尺寸</span>' +
          '<input id="launchSize" type="range" min="20" max="100" step="1" value="' + launchSize + '">' +
          '<span id="launchSizeValue">' + launchSize + '%</span></div>' +
        '<div class="setting-row compact"><span>显示方式</span><div class="seg-group">' +
          '<button class="seg' + (launch.fit === 'contain' ? ' active' : '') + '" data-action="set-launch-fit" data-value="contain">完整</button>' +
          '<button class="seg' + (launch.fit === 'cover' ? ' active' : '') + '" data-action="set-launch-fit" data-value="cover">铺满</button>' +
        '</div></div>' +
        '<div class="slider-row"><span>时长</span>' +
          '<input id="launchDuration" type="range" min="5" max="50" step="1" value="' + launchTenth + '">' +
          '<span id="launchDurationValue">' + (launchTenth / 10).toFixed(1) + 's</span></div>' +
        '<div class="setting-row compact"><span>每次启动播放</span>' +
          '<button class="switch' + (launch.enabled ? ' on' : '') + '" data-action="toggle-launch" aria-label="每次启动播放"></button></div>' +
        '<button class="soft-btn wide" style="margin-top:10px" data-action="preview-launch">' + icon('play', 14) + ' 预览启动动画</button>' +
      '</div>' +
      '<div class="appearance-block">' +
        '<div class="appearance-label">数据导出</div>' +
        '<div class="tip" style="margin-top:6px">仅导出你勾选的内容；不会读取手机里的其他文件，也不会自动上传。</div>' +
        '<label class="check-row"><input type="checkbox" id="exportArticles" checked> 文章与图片识别记录</label>' +
        '<label class="check-row"><input type="checkbox" id="exportFavorites" checked> 收藏夹</label>' +
        '<label class="check-row"><input type="checkbox" id="exportAppearance"> 外观配置（不含图片）</label>' +
        '<div class="export-actions">' +
          '<button class="soft-btn" data-action="export-package">' + icon('folder', 15) + ' 生成数据包</button>' +
          '<button class="soft-btn" data-action="open-viewer">打开数据包查看器</button>' +
        '</div>' +
      '</div>' +
      '<button class="action-row" data-action="reset-appearance">恢复默认外观</button>' +
      '<button class="action-row cancel" data-action="close-sheet">完成</button>');
  }

  function reopenAppearanceSheet() {
    openAppearanceSheet();
  }

  function openSkinSheet(key, label) {
    if (!key) return;
    pendingSkinKey = key;
    pendingSkinLabel = label || '组件';
    var skin = appearance.skins[key];
    var hasImage = skin && skin.image;
    var percent = Math.round((skin && typeof skin.opacity === 'number' ? skin.opacity : 0.35) * 100);

    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="sel-head"><div><div class="sel-title">组件图案</div><div class="ws-phonetic">' + esc(pendingSkinLabel) + '</div></div></div>' +
      '<div class="skin-preview' + (hasImage ? '' : ' empty') + '"' +
        (hasImage ? ' style="background-image:url(\'' + skin.image + '\')"' : '') + '>' +
        (hasImage ? '' : '<span>暂无图案</span>') +
      '</div>' +
      '<div class="row-2">' +
        '<button class="soft-btn" data-action="pick-skin">' + icon('folder', 15) + ' 从相册选择</button>' +
        '<button class="soft-btn" data-action="clear-skin">清除图案</button>' +
      '</div>' +
      '<div class="slider-row"><span>图案透明度</span>' +
        '<input id="skinOpacity" type="range" min="0" max="100" step="1" value="' + percent + '">' +
        '<span id="skinOpacityValue">' + percent + '%</span></div>' +
      '<button class="action-row cancel" data-action="close-sheet">完成</button>');
  }

  function reopenSkinSheet() {
    openSkinSheet(pendingSkinKey, pendingSkinLabel);
  }

  function enterSkinEditing() {
    appearance.editing = true;
    if (phone) phone.classList.add('skin-editing');
    closeSheet();
    toast('编辑模式：点击任意组件更换图案');
  }

  function exitSkinEditing() {
    appearance.editing = false;
    if (phone) phone.classList.remove('skin-editing');
    render();
    toast('已完成外观编辑');
  }

  function resetAppearance() {
    appearance.wallpaper = { image: '', opacity: 0.3 };
    appearance.skins = {};
    appearance.launch = { image: '', type: '', size: 60, fit: 'contain', duration: 2.2, enabled: true };
    appearance.editing = false;
    if (phone) phone.classList.remove('skin-editing');
    var launchScreen = $id('launchScreen');
    if (launchScreen) launchScreen.style.display = 'none';
    clearTimeout(launchTimer);
    applyWallpaper();
    persistAppearance();
    closeSheet();
    render();
    toast('已恢复默认外观');
  }

  /* ==================== 持久化 ==================== */

  function persist() {
    saveJSON(STORAGE_KEY, {
      articles: state.articles,
      favorites: state.favorites,
      fontSize: state.fontSize,
      showTranslations: state.showTranslations,
      theme: state.theme,
      readMode: state.readMode,
      playerSettings: state.playerSettings
    });
  }

  function isFavorited(type, text) {
    var target = type === 'word' ? normalizeKey(text) : String(text || '').trim().toLowerCase();
    return state.favorites.some(function (item) {
      if (item.type !== type) return false;
      var value = type === 'word' ? normalizeKey(item.text) : String(item.text || '').trim().toLowerCase();
      return value === target;
    });
  }

  function addFavorite(item) {
    if (!item || !item.text) return false;
    if (isFavorited(item.type, item.text)) return false;
    state.favorites.unshift({
      id: uid(),
      type: item.type,
      text: item.text,
      translation: item.translation || '',
      phonetic: item.phonetic || '',
      analysis: item.analysis || null,
      addedAt: Date.now()
    });
    persist();
    return true;
  }

  function removeFavoriteById(id) {
    state.favorites = state.favorites.filter(function (item) { return item.id !== id; });
    persist();
  }

  function favoritesSummary() {
    var result = { words: 0, sentences: 0 };
    state.favorites.forEach(function (item) {
      if (item.type === 'sentence') result.sentences += 1;
      else result.words += 1;
    });
    return result;
  }

  /* ==================== 主题与字号 ==================== */

  function initialTheme() {
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) return 'dark';
    return 'light';
  }

  function applyTheme(theme, save) {
    state.theme = theme === 'dark' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', state.theme);
    var meta = document.querySelector('meta[name="color-scheme"]');
    if (meta) meta.setAttribute('content', state.theme);
    if (save) persist();
  }

  function toggleTheme() {
    var next = state.theme === 'dark' ? 'light' : 'dark';
    applyTheme(next, true);
    render();
    toast(next === 'dark' ? '已切换为深色模式' : '已切换为浅色模式');
  }

  function changeFont(delta) {
    var next = Math.min(24, Math.max(15, state.fontSize + delta));
    if (next === state.fontSize) {
      toast(delta > 0 ? '已是最大字号' : '已是最小字号');
      return;
    }
    state.fontSize = next;
    persist();
    render();
  }

  function toggleReadMode() {
    state.readMode = !state.readMode;
    if (state.readMode) {
      state.selection = emptySelection();
      selectionData = null;
      if (sheetOpen) closeSheet();
    }
    persist();
    render();
    toast(state.readMode ? '阅读模式已开启：单词选中已关闭' : '阅读模式已关闭：可以长按选词');
  }

  /* ==================== 文本处理 ==================== */

  function splitParagraphs(content) {
    var normalized = String(content || '').replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    var blocks = normalized.split(/\n\s*\n/).map(function (block) {
      return block.split('\n').map(function (line) { return line.trim(); }).filter(Boolean).join(' ');
    }).filter(Boolean);
    if (blocks.length) return blocks;
    var single = normalized.trim();
    return single ? [single] : [];
  }

  function tokenizeParagraph(text) {
    var pieces = String(text || '').split(/(\s+)/);
    var tokens = [];
    var index = 0;
    for (var i = 0; i < pieces.length; i += 1) {
      var piece = pieces[i];
      if (piece === '') continue;
      if (/^\s+$/.test(piece)) {
        tokens.push({ type: 'space', text: ' ', i: -1, key: '' });
        continue;
      }
      var core = piece.replace(/^[^A-Za-z]+|[^A-Za-z]+$/g, '');
      var isWord = !!core && /^[A-Za-z][A-Za-z'’\-]*$/.test(core);
      tokens.push({
        type: isWord ? 'word' : 'punct',
        text: piece,
        i: index,
        key: isWord ? normalizeKey(core) : ''
      });
      index += 1;
    }
    return { tokens: tokens, count: index };
  }

  function countWords(text) {
    return String(text || '').trim().split(/\s+/).filter(Boolean).length;
  }

  function currentArticle() {
    for (var i = 0; i < state.articles.length; i += 1) {
      if (state.articles[i].id === state.articleId) return state.articles[i];
    }
    return null;
  }

  function findArticle(id) {
    for (var i = 0; i < state.articles.length; i += 1) {
      if (state.articles[i].id === id) return state.articles[i];
    }
    return null;
  }

  function articleIsFullyTranslated(article) {
    if (!article) return false;
    var paragraphs = splitParagraphs(article.content);
    if (!paragraphs.length) return false;
    for (var i = 0; i < paragraphs.length; i += 1) {
      if (!article.translations || !article.translations[i]) return false;
    }
    return true;
  }

  function isSelectedToken(p, i) {
    var selection = state.selection;
    if (!selection.mode || selection.p !== p) return false;
    if (selection.anchor == null || selection.focus == null) return false;
    var low = Math.min(selection.anchor, selection.focus);
    var high = Math.max(selection.anchor, selection.focus);
    return i >= low && i <= high;
  }

  function tokensHtml(paragraphIndex, parsed) {
    var selection = state.selection;
    var html = '';
    for (var i = 0; i < parsed.tokens.length; i += 1) {
      var token = parsed.tokens[i];
      if (token.type === 'space') {
        html += ' ';
        continue;
      }
      var classes = token.type === 'word' ? 'token word' : 'punct';
      if (isSelectedToken(paragraphIndex, token.i)) classes += ' sel';
      if (token.type === 'word' && selection.mode && selection.p === paragraphIndex && selection.anchor === token.i) {
        classes += ' anchor';
      }
      if (token.type === 'word') {
        html += '<span class="' + classes + '" data-p="' + paragraphIndex + '" data-i="' + token.i +
          '" data-w="' + esc(token.key) + '">' + esc(token.text) + '</span>';
      } else {
        html += '<span class="' + classes + '">' + esc(token.text) + '</span>';
      }
    }
    return html;
  }

  function selectionRangeText(p, from, to) {
    if (p == null || from == null || to == null) return '';
    var article = currentArticle();
    if (!article) return '';
    var paragraphs = splitParagraphs(article.content);
    if (!paragraphs[p]) return '';
    var parsed = tokenizeParagraph(paragraphs[p]);
    var low = Math.min(from, to);
    var high = Math.max(from, to);
    var output = '';
    var started = false;
    for (var i = 0; i < parsed.tokens.length; i += 1) {
      var token = parsed.tokens[i];
      if (token.type === 'space') {
        if (started) output += ' ';
        continue;
      }
      if (token.i >= low && token.i <= high) {
        started = true;
        output += token.text;
      }
    }
    return output.trim();
  }

  function selectionWordCount(p, from, to) {
    var article = currentArticle();
    if (!article || p == null) return 0;
    var paragraphs = splitParagraphs(article.content);
    if (!paragraphs[p]) return 0;
    var parsed = tokenizeParagraph(paragraphs[p]);
    var low = Math.min(from, to);
    var high = Math.max(from, to);
    var count = 0;
    for (var i = 0; i < parsed.tokens.length; i += 1) {
      var token = parsed.tokens[i];
      if (token.type === 'word' && token.i >= low && token.i <= high) count += 1;
    }
    return count;
  }

  function selectionWords(p, from, to) {
    var article = currentArticle();
    if (!article || p == null) return [];
    var paragraphs = splitParagraphs(article.content);
    if (!paragraphs[p]) return [];
    var parsed = tokenizeParagraph(paragraphs[p]);
    var low = Math.min(from, to);
    var high = Math.max(from, to);
    var seen = {};
    var words = [];
    for (var i = 0; i < parsed.tokens.length; i += 1) {
      var token = parsed.tokens[i];
      if (token.type !== 'word') continue;
      if (token.i < low || token.i > high) continue;
      if (seen[token.key]) continue;
      seen[token.key] = true;
      var entries = findEntries(token.key);
      words.push({
        word: entries.length ? entries[0].word : token.key,
        phonetic: entries.length ? entries[0].phonetic : '',
        meaning: entries.length ? entries[0].meaning : '（四六级词库未收录）'
      });
    }
    return words;
  }

  /* ==================== 渲染 ==================== */

  function render(options) {
    var animate = !!(options && options.animate);
    var scrollEl = viewport.querySelector('.scroll');
    var scrollTop = scrollEl ? scrollEl.scrollTop : 0;

    viewport.innerHTML = renderView(animate);
    tagSkinTargets();
    applySkins();

    var nextScroll = viewport.querySelector('.scroll');
    if (nextScroll) nextScroll.scrollTop = scrollTop;
  }

  function viewAnimClass(animate) {
    return animate ? '' : ' no-anim';
  }

  function renderView(animate) {
    if (state.view === 'import') return importView(animate);
    if (state.view === 'reader') return readerView(animate);
    if (state.view === 'vocabulary') return vocabularyView(animate);
    if (state.view === 'bank') return bankView(animate);
    if (state.view === 'backup') return backupView(animate);
    return homeView(animate);
  }

  function homeView(animate) {
    var daily = state.dailyWord ? dailyCardHtml(state.dailyWord) : '';
    var summary = favoritesSummary();
    var favoriteText = summary.words || summary.sentences
      ? summary.words + ' 个单词' + (summary.sentences ? ' · ' + summary.sentences + ' 句句子' : '')
      : '阅读时长按单词组句，或点击单词收藏';
    var personal = personalArticles();
    var list = personal.length
      ? personal.map(articleRowHtml).join('')
      : emptyArticlesHtml();

    return '' +
      '<div class="view view-home' + viewAnimClass(animate) + '">' +
        '<div class="scroll home-scroll">' +
          '<div class="home-header">' +
            appIconHtml(40) +
            '<div class="home-header-text">' +
              '<h1>一念词间</h1>' +
              '<p>四六级英语 · 导入 · 翻译 · 词汇</p>' +
            '</div>' +
            '<button class="appearance-btn" data-action="open-appearance" aria-label="外观与壁纸">' + icon('palette', 18) + '</button>' +
          '</div>' +
          '<div class="import-card" role="button" tabindex="0" data-action="open-import">' +
            '<div class="import-top">' +
              '<span class="import-icon">' + icon('docPlus', 22) + '</span>' +
              '<span class="import-arrow">' + icon('arrowUpRight', 16) + '</span>' +
            '</div>' +
            '<div class="import-title">导入英语文章</div>' +
            '<div class="import-sub">粘贴文本或从文件导入，自动生成中文译文</div>' +
          '</div>' +
          daily +
          '<div class="level-row">' + levelCardHtml('cet4') + levelCardHtml('cet6') + '</div>' +
          bankCardHtml() +
          '<div class="wordbook-card" role="button" tabindex="0" data-action="open-tab" data-tab="favorites">' +
            '<span class="article-icon" style="background:rgba(255,159,10,.14);color:var(--orange)">' + icon('star', 18) + '</span>' +
            '<div class="article-main">' +
              '<div class="wordbook-title">我的收藏</div>' +
              '<div class="wordbook-sub">' + esc(favoriteText) + '</div>' +
            '</div>' +
            '<span style="color:var(--text-3)">' + icon('chevronRight', 14) + '</span>' +
          '</div>' +
          backupCardHtml() +
          '<div class="section-head">' +
            '<h2>我的文章</h2>' +
            (personal.length ? '<span>' + personal.length + ' 篇</span>' : '') +
          '</div>' +
          list +
        '</div>' +
      '</div>';
  }

  function backupCardHtml() {
    var count = state.backup.records.length;
    var subtitle = count
      ? '最近备份 · ' + new Date(state.backup.records[0].createdAt).toLocaleDateString('zh-CN')
      : '把选中的照片与文件备份到你的服务器';
    return '' +
      '<div class="bank-card" role="button" tabindex="0" data-action="open-backup">' +
        '<div class="bank-card-main">' +
          '<span class="bank-icon" style="background:rgba(52,199,89,.12);color:#34c759">' + icon('shield', 20) + '</span>' +
          '<div>' +
            '<div class="bank-title">安全备份</div>' +
            '<div class="bank-sub">' + esc(subtitle) + '</div>' +
          '</div>' +
        '</div>' +
        '<span class="bank-count">' + (count ? count + ' 次' : '未备份') + '</span>' +
        '<span style="color:var(--text-3)">' + icon('chevronRight', 14) + '</span>' +
      '</div>';
  }

  function personalArticles() {
    return state.articles.filter(function (article) { return !article.bank; });
  }

  function bankSamples() {
    return state.articles.filter(function (article) { return article.bank === true; });
  }

  function bankCardHtml() {
    var total = BANK_INDEX.length + OFFICIAL_SOURCES.length + bankSamples().length;
    return '' +
      '<div class="bank-card" role="button" tabindex="0" data-action="open-bank">' +
        '<div class="bank-card-main">' +
          '<span class="bank-icon">' + icon('book', 20) + '</span>' +
          '<div>' +
            '<div class="bank-title">四六级真题题库</div>' +
            '<div class="bank-sub">模拟练习 · 历年真题目录 · 官方大纲</div>' +
          '</div>' +
        '</div>' +
        '<span class="bank-count">' + total + ' 项</span>' +
        '<span style="color:var(--text-3)">' + icon('chevronRight', 14) + '</span>' +
      '</div>';
  }

  function levelCardHtml(level) {
    var words = dictionary[level] || [];
    return '' +
      '<div class="level-card" role="button" tabindex="0" data-action="open-tab" data-tab="' + level + '">' +
        '<div class="level-top">' +
          '<span class="level-tag">' + levelLabel(level) + '</span>' +
          '<span style="color:var(--text-3)">' + icon('chevronRight', 12) + '</span>' +
        '</div>' +
        '<div class="level-title">' + (level === 'cet4' ? '四级词汇' : '六级词汇') + '</div>' +
        '<div class="level-count">' + words.length + ' 个核心词</div>' +
      '</div>';
  }

  function dailyCardHtml(word) {
    return '' +
      '<div class="daily-card">' +
        '<div class="daily-head">' +
          '<span class="daily-tag">今日词汇 · ' + levelLabel(word.level) + '</span>' +
          '<button class="circle-btn sm" data-action="shuffle-word" aria-label="换一个单词">' + icon('refresh', 14) + '</button>' +
        '</div>' +
        '<div class="daily-word-row">' +
          '<span class="daily-word">' + esc(word.word) + '</span>' +
          (word.phonetic ? '<span class="daily-phonetic">' + esc(word.phonetic) + '</span>' : '') +
          '<button class="circle-btn sm" style="margin-left:auto" data-action="speak" data-text="' + esc(word.word) + '" aria-label="朗读">' + icon('speaker', 14) + '</button>' +
        '</div>' +
        '<div class="daily-meaning">' + esc(word.meaning) + '</div>' +
        '<button class="daily-link" data-action="open-word" data-word="' + esc(normalizeKey(word.word)) + '">查看完整释义 ›</button>' +
      '</div>';
  }

  function articleRowHtml(article) {
    var paragraphs = splitParagraphs(article.content);
    var words = countWords(article.content);
    var preview = paragraphs[0] || article.content;
    var translated = articleIsFullyTranslated(article);
    return '' +
      '<div class="article-row" role="button" tabindex="0" data-action="open-article" data-id="' + esc(article.id) + '">' +
        '<span class="article-icon">' + icon('doc', 18) + '</span>' +
        '<div class="article-main">' +
          '<div class="article-title">' + esc(article.title) + '</div>' +
          '<div class="article-preview">' + esc(truncate(preview, 86)) + '</div>' +
          '<div class="article-meta">' +
            '<span>' + words + ' 词</span><span>·</span><span>约 ' + Math.max(1, Math.ceil(words / 200)) + ' 分钟</span>' +
            (translated ? '<span>·</span><span class="done">已翻译</span>' : '') +
            (article.kind === 'ocr' ? '<span class="ocr-tag">图片识别</span>' : '') +
          '</div>' +
        '</div>' +
        '<button class="article-menu" data-action="article-menu" data-id="' + esc(article.id) + '" aria-label="更多操作">' + icon('more', 18) + '</button>' +
      '</div>';
  }

  function emptyArticlesHtml() {
    return '' +
      '<div class="empty-card">' +
        '还没有文章，点击上方卡片导入一篇开始精读吧。<br>' +
        '<button class="daily-link" data-action="reset-demo" style="margin-top:10px">恢复示例文章</button>' +
      '</div>';
  }

  function readerView(animate) {
    var article = currentArticle();
    if (!article) {
      return '<div class="view"><div class="empty-card" style="margin:60px 20px">文章不存在</div></div>';
    }

    var paragraphs = splitParagraphs(article.content);
    var parsedList = paragraphs.map(tokenizeParagraph);
    var translatedCount = 0;
    paragraphs.forEach(function (_, index) {
      if (article.translations && article.translations[index]) translatedCount += 1;
    });
    var fully = paragraphs.length > 0 && translatedCount === paragraphs.length;

    var paraHtml = paragraphs.map(function (paragraph, index) {
      var translation = article.translations && article.translations[index];
      var visible = state.showTranslations && translation;
      var offline = translation && translation.indexOf('（离线逐词示意）') === 0;
      var content = translation && offline ? translation.replace('（离线逐词示意）', '') : translation;
      return '' +
        '<div class="para-card">' +
          '<p class="para-text">' + tokensHtml(index, parsedList[index]) + '</p>' +
          (visible
            ? '<div class="translation"><span class="bar"></span><span>' +
              (offline ? '<span class="offline-tag">离线逐词示意</span><br>' : '') +
              esc(content) + '</span></div>'
            : '') +
        '</div>';
    }).join('');

    var translateBlock = (!fully && !state.translating)
      ? '<button class="translate-btn" data-action="translate">' + icon('translate', 18) + ' 一键翻译全文</button>'
      : '';

    var progressBlock = state.translating
      ? '<div class="progress-card"><span class="spinner"></span><span>正在翻译 ' + state.progress.done + '/' + state.progress.total + ' 段…</span></div>'
      : '';

    var errorBlock = state.error ? '<div class="error-card">' + esc(state.error) + '</div>' : '';

    var lockNote = state.readMode
      ? '<div class="reader-lock-note">' + icon('eyeOff', 13) + ' 阅读模式已开启，单词选中已关闭</div>'
      : '';

    var completion = fully && !state.translating
      ? '<div class="completion">' + icon('check', 15) + ' 全文翻译完成</div>'
      : '';

    var themeIcon = state.theme === 'dark' ? 'sun' : 'moon';
    var themeLabel = state.theme === 'dark' ? '浅色' : '深色';
    var modeIcon = state.readMode ? 'eyeOff' : 'eye';
    var modeLabel = state.readMode ? '阅读中' : '阅读模式';

    return '' +
      '<div class="view view-reader' + viewAnimClass(animate) + (state.readMode ? ' reader-locked' : '') +
        '" style="--reader-font:' + state.fontSize + 'px">' +
        '<div class="navbar">' +
          '<button class="nav-btn" data-action="back">' + icon('chevronLeft', 18) + ' 返回</button>' +
          '<div class="nav-title">' + esc(article.title) + '</div>' +
          '<div class="nav-trailing"></div>' +
        '</div>' +
        '<div class="reader-toolbar">' +
          '<button class="tool-btn" data-action="font-dec" aria-label="减小字号"><span class="tool-glyph">A−</span><span>字号</span></button>' +
          '<button class="tool-btn" data-action="font-inc" aria-label="增大字号"><span class="tool-glyph">A+</span><span>字号</span></button>' +
          '<button class="tool-btn" data-action="toggle-theme">' + icon(themeIcon, 18) + '<span>' + themeLabel + '</span></button>' +
          '<button class="tool-btn' + (state.readMode ? ' active' : '') + '" data-action="toggle-read-mode">' + icon(modeIcon, 18) + '<span>' + modeLabel + '</span></button>' +
          '<button class="tool-btn" data-action="translate">' + icon('translate', 18) + '<span>翻译</span></button>' +
          '<button class="tool-btn" data-action="open-player-settings" data-mode="article">' + icon('play', 18) + '<span>朗读</span></button>' +
          '<button class="tool-btn" data-action="open-favorites">' + icon('star', 18) + '<span>收藏夹</span></button>' +
          '<button class="tool-btn" data-action="reader-menu">' + icon('more', 18) + '<span>更多</span></button>' +
        '</div>' +
        '<div class="scroll reader-scroll">' +
          '<h1 class="reader-title">' + esc(article.title) + '</h1>' +
          '<div class="reader-meta">' +
            '<span>' + countWords(article.content) + ' 词</span><span>·</span>' +
            '<span>' + paragraphs.length + ' 段</span><span>·</span>' +
            '<span>约 ' + Math.max(1, Math.ceil(countWords(article.content) / 200)) + ' 分钟</span>' +
            (fully ? '<span>·</span><span class="done">已翻译</span>' : '') +
          '</div>' +
          '<div class="reader-hint">' + (state.readMode
            ? '当前处于阅读模式，单词选中已关闭'
            : '单击单词查词；长按单词后继续点击其他单词，可组成句子并查看语法成分') + '</div>' +
          lockNote +
          translateBlock +
          progressBlock +
          errorBlock +
          paraHtml +
          completion +
        '</div>' +
      '</div>';
  }

  function vocabularyView(animate) {
    var isFavorites = state.tab === 'favorites';
    var count = isFavorites ? filteredFavorites().length : filteredWords().length;
    var rows = isFavorites ? favoriteRowsHtml() : vocabRowsHtml();
    var tabs = [
      { key: 'cet4', label: '四级' },
      { key: 'cet6', label: '六级' },
      { key: 'favorites', label: '收藏夹' }
    ];

    return '' +
      '<div class="view view-vocabulary' + viewAnimClass(animate) + '">' +
        '<div class="navbar">' +
          '<button class="nav-btn" data-action="back">' + icon('chevronLeft', 18) + ' 返回</button>' +
          '<div class="nav-title">词汇学习</div>' +
          '<div class="nav-trailing">' +
            '<button class="nav-btn" data-action="open-player-settings" data-mode="words" aria-label="自动播放">' + icon('play', 19) + '</button>' +
          '</div>' +
        '</div>' +
        '<div class="segmented">' +
          tabs.map(function (tab) {
            return '<button class="seg' + (state.tab === tab.key ? ' active' : '') + '" data-action="switch-tab" data-tab="' +
              tab.key + '">' + tab.label + '</button>';
          }).join('') +
        '</div>' +
        '<div class="searchbar">' +
          icon('search', 16) +
          '<input id="vocabSearch" type="text" placeholder="搜索单词、释义或收藏内容" value="' + esc(state.search) + '" autocomplete="off">' +
          '<button id="searchClear" class="nav-btn" style="padding:0;visibility:' + (state.search ? 'visible' : 'hidden') +
            '" data-action="clear-search" aria-label="清空搜索">' + icon('close', 14) + '</button>' +
        '</div>' +
        '<div class="scroll vocab-scroll">' +
          '<div class="list-head" id="vocabCount">' + (isFavorites
            ? '共 ' + count + ' 条收藏'
            : '共 ' + count + ' 个单词') + '</div>' +
          '<div id="vocabList">' + rows + '</div>' +
        '</div>' +
      '</div>';
  }

  function filteredWords() {
    var all = dictionary[state.tab] || [];
    var query = state.search.trim().toLowerCase();
    if (!query) return all;
    return all.filter(function (entry) {
      return entry.word.toLowerCase().indexOf(query) >= 0 || entry.meaning.indexOf(query) >= 0;
    });
  }

  function filteredFavorites() {
    var query = state.search.trim().toLowerCase();
    if (!query) return state.favorites;
    return state.favorites.filter(function (item) {
      var haystack = (item.text + ' ' + (item.translation || '')).toLowerCase();
      return haystack.indexOf(query) >= 0;
    });
  }

  function vocabRowsHtml() {
    var words = filteredWords();
    if (!words.length) return emptyListHtml('没有找到匹配的单词');
    return words.map(function (entry) {
      return '' +
        '<div class="vocab-row">' +
          '<div class="vocab-main" role="button" tabindex="0" data-action="open-word" data-word="' + esc(normalizeKey(entry.word)) + '">' +
            '<div class="vocab-word-line">' +
              '<span class="vocab-word">' + esc(entry.word) + '</span>' +
              (entry.phonetic ? '<span class="vocab-phonetic">' + esc(entry.phonetic) + '</span>' : '') +
              (isFavorited('word', entry.word) ? '<span class="star-dot">★</span>' : '') +
            '</div>' +
            '<div class="vocab-meaning">' + esc(entry.meaning) + '</div>' +
          '</div>' +
          '<button class="circle-btn sm" data-action="speak" data-text="' + esc(entry.word) + '" aria-label="朗读">' + icon('speaker', 14) + '</button>' +
        '</div>';
    }).join('');
  }

  function favoriteRowsHtml() {
    var items = filteredFavorites();
    if (!items.length) {
      return emptyListHtml(state.search
        ? '没有找到匹配的收藏'
        : '收藏夹还是空的：阅读时长按单词组句，或点击单词收藏');
    }
    return items.map(function (item) {
      if (item.type === 'sentence') {
        return '' +
          '<div class="fav-row">' +
            '<div class="fav-main" role="button" tabindex="0" data-action="open-fav-sentence" data-id="' + esc(item.id) + '">' +
              '<span class="fav-tag">句子</span>' +
              '<div class="fav-sentence-text">' + esc(item.text) + '</div>' +
              '<div class="fav-sentence-trans">' + esc(item.translation || '暂无译文') + '</div>' +
            '</div>' +
            '<button class="circle-btn sm" data-action="speak" data-text="' + esc(item.text) + '" aria-label="朗读">' + icon('speaker', 14) + '</button>' +
            '<button class="circle-btn sm" style="background:transparent;color:var(--text-3)" data-action="remove-fav" data-id="' + esc(item.id) + '" aria-label="移除收藏">' + icon('close', 14) + '</button>' +
          '</div>';
      }
      return '' +
        '<div class="fav-row">' +
          '<div class="fav-main" role="button" tabindex="0" data-action="open-word" data-word="' + esc(normalizeKey(item.text)) + '">' +
            '<span class="fav-tag">单词</span>' +
            '<div class="fav-word-line">' +
              '<span class="fav-word">' + esc(item.text) + '</span>' +
              (item.phonetic ? '<span class="fav-phonetic">' + esc(item.phonetic) + '</span>' : '') +
            '</div>' +
            '<div class="fav-meaning">' + esc(item.translation || '') + '</div>' +
          '</div>' +
          '<button class="circle-btn sm" data-action="speak" data-text="' + esc(item.text) + '" aria-label="朗读">' + icon('speaker', 14) + '</button>' +
          '<button class="circle-btn sm" style="background:transparent;color:var(--text-3)" data-action="remove-fav" data-id="' + esc(item.id) + '" aria-label="移除收藏">' + icon('close', 14) + '</button>' +
        '</div>';
    }).join('');
  }

  function emptyListHtml(message) {
    return '<div class="empty-card" style="margin-top:8px">' + esc(message) + '</div>';
  }

  function backupView(animate) {
    var settings = state.backup.settings;
    var pending = state.backup.pending;
    var records = state.backup.records;
    var total = backupTotalBytes(pending);

    var pendingHtml = pending.length
      ? pending.map(function (file) {
          return '<div class="backup-file-row">' +
            '<span class="backup-file-name">' + esc(file.name) + '</span>' +
            '<span class="backup-file-size">' + formatBytes(file.size) + '</span>' +
            '</div>';
        }).join('')
      : '<div class="empty-card" style="margin-top:8px">还没有选择文件</div>';

    var recordsHtml = records.length
      ? records.map(function (record) {
          return '<div class="backup-file-row" role="button" tabindex="0" data-action="open-backup-record" data-id="' + esc(record.id) + '">' +
            '<span class="backup-file-name">' + esc(new Date(record.createdAt).toLocaleString('zh-CN')) + ' · ' + record.count + ' 个文件</span>' +
            '<span class="backup-file-size">' + formatBytes(record.bytes) + ' · ' + esc(record.statusLabel) + '</span>' +
            '</div>';
        }).join('')
      : '<div class="empty-card" style="margin-top:8px">暂无备份记录</div>';

    return '' +
      '<div class="view view-backup' + viewAnimClass(animate) + '">' +
        '<div class="navbar">' +
          '<button class="nav-btn" data-action="back">' + icon('chevronLeft', 18) + ' 返回</button>' +
          '<div class="nav-title">安全备份</div>' +
          '<div class="nav-trailing"><button class="nav-btn" data-action="open-backup-console">管理台</button></div>' +
        '</div>' +
        '<div class="scroll bank-scroll">' +
          '<div class="bank-hero" style="background:linear-gradient(135deg,rgba(52,199,89,.12),rgba(61,107,245,.10))">' +
            '<div class="bank-hero-title">客户数据备份</div>' +
            '<div class="bank-hero-text">仅上传你在下方主动选择的文件，或经授权后从相册导出的照片/视频；不会扫描其他 App 或系统文件。备份保存到你配置的服务器。</div>' +
          '</div>' +
          '<div class="appearance-block">' +
            '<div class="appearance-label">备份服务器</div>' +
            '<div class="field" style="margin-top:10px;background:var(--card)">' + icon('cloud', 16) +
              '<input id="backupServerURL" placeholder="https://你的备份服务器" value="' + esc(settings.url) + '">' +
            '</div>' +
            '<div class="field" style="margin-top:8px;background:var(--card)">' + icon('shield', 16) +
              '<input id="backupToken" type="password" placeholder="访问令牌（Token）" value="' + esc(settings.token) + '">' +
            '</div>' +
            '<div class="row-2" style="margin-top:10px">' +
              '<button class="soft-btn" data-action="save-backup-settings">保存配置</button>' +
              '<button class="soft-btn" data-action="pick-backup-files">选择文件</button>' +
            '</div>' +
            '<div class="tip">未配置服务器时，备份会以本地记录形式演示；配置后文件会逐个上传到 /api/backups 接口。</div>' +
          '</div>' +
          '<div class="appearance-block">' +
            '<div class="appearance-label">待备份 · ' + pending.length + ' 个文件（' + formatBytes(total) + '）</div>' +
            pendingHtml +
            '<div class="row-2" style="margin-top:10px">' +
              '<button class="soft-btn" data-action="start-backup">开始备份</button>' +
              '<button class="soft-btn" data-action="clear-backup-pending">清空待备份</button>' +
            '</div>' +
            (state.backup.uploading
              ? '<div class="progress-card" style="margin-top:10px"><span class="spinner"></span><span>' + esc(state.backup.status) + '</span></div>'
              : '') +
          '</div>' +
          '<div class="bank-section">' +
            '<div class="bank-section-title">备份记录<span>' + records.length + ' 次</span></div>' +
            recordsHtml +
          '</div>' +
        '</div>' +
      '</div>';
  }

  function handleBackupFiles(fileList) {
    var files = Array.prototype.slice.call(fileList || []);
    if (!files.length) return;
    if (state.backup.pending.length + files.length > 100) {
      toast('单次最多备份 100 个文件');
      files = files.slice(0, Math.max(0, 100 - state.backup.pending.length));
    }
    files.forEach(function (file) {
      if (file.size > 500 * 1024 * 1024) {
        toast('已跳过超过 500MB 的文件：' + file.name);
        return;
      }
      state.backup.pending.push(file);
    });
    render();
    toast('已选择 ' + state.backup.pending.length + ' 个文件');
  }

  function saveBackupSettings() {
    var urlInput = $id('backupServerURL');
    var tokenInput = $id('backupToken');
    var url = urlInput ? urlInput.value.trim() : '';
    if (url && !/^https?:\/\//i.test(url)) {
      toast('服务器地址需以 http:// 或 https:// 开头');
      return;
    }
    state.backup.settings.url = url.replace(/\/$/, '');
    state.backup.settings.token = tokenInput ? tokenInput.value.trim() : '';
    persistBackup();
    toast('备份服务器配置已保存');
  }

  function startBackup() {
    if (state.backup.uploading) return;
    var pending = state.backup.pending.slice();
    if (!pending.length) {
      toast('请先选择要备份的文件');
      return;
    }

    var settings = state.backup.settings;
    var batchId = 'B' + Date.now();
    var total = backupTotalBytes(pending);
    var failed = 0;

    state.backup.uploading = true;
    state.backup.progress = { done: 0, total: pending.length };
    state.backup.status = '准备备份…';
    render();

    var chain = Promise.resolve();

    if (settings.url) {
      pending.forEach(function (file, index) {
        chain = chain.then(function () {
          state.backup.status = '正在上传 ' + (index + 1) + '/' + pending.length + '：' + file.name;
          state.backup.progress.done = index;
          render();
          var form = new FormData();
          form.append('file', file, file.name);
          var headers = {};
          if (settings.token) headers.Authorization = 'Bearer ' + settings.token;
          return fetch(settings.url.replace(/\/$/, '') + '/api/backups/' + batchId + '/files', {
            method: 'POST',
            headers: headers,
            body: form
          }).then(function (response) {
            if (!response.ok) failed += 1;
          }).catch(function () {
            failed += 1;
          });
        });
      });
    } else {
      chain = chain.then(function () {
        return new Promise(function (resolve) { setTimeout(resolve, 600); });
      });
    }

    chain.then(function () {
      state.backup.records.unshift({
        id: batchId,
        createdAt: Date.now(),
        count: pending.length,
        bytes: total,
        status: failed ? 'partial' : (settings.url ? 'uploaded' : 'local'),
        statusLabel: failed ? '部分失败' : (settings.url ? '已上传' : '本地演示'),
        server: settings.url,
        files: pending.map(function (file) {
          return { name: file.name, size: file.size, type: file.type || '' };
        })
      });
      if (state.backup.records.length > 50) {
        state.backup.records = state.backup.records.slice(0, 50);
      }
      state.backup.pending = [];
      state.backup.uploading = false;
      state.backup.progress = { done: pending.length, total: pending.length };
      state.backup.status = '';
      persistBackup();
      render();
      toast(failed ? '备份完成，但有 ' + failed + ' 个文件失败' : '备份完成');
    });
  }

  function openBackupRecordSheet(record) {
    if (!record) return;
    var files = Array.isArray(record.files) ? record.files : [];
    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="action-sheet">' +
        '<div class="action-title">备份记录 · ' + esc(new Date(record.createdAt).toLocaleString('zh-CN')) + '</div>' +
        '<div class="bank-sheet-body">' +
          '<p class="tip" style="margin-top:0">批次：' + esc(record.id) + '</p>' +
          '<p class="tip">文件：' + record.count + ' 个 · ' + formatBytes(record.bytes) + ' · ' + esc(record.statusLabel) + '</p>' +
          (record.server
            ? '<p class="tip">服务器：' + esc(record.server) + '</p>'
            : '<p class="tip">未配置服务器（本地演示记录）</p>') +
        '</div>' +
        files.map(function (file) {
          return '<div class="backup-file-row">' +
            '<span class="backup-file-name">' + esc(file.name) + '</span>' +
            '<span class="backup-file-size">' + formatBytes(file.size) + '</span>' +
            '</div>';
        }).join('') +
        '<button class="action-row cancel" data-action="close-sheet">关闭</button>' +
      '</div>');
  }

  function bankView(animate) {
    var filter = state.bankFilter;
    function matchLevel(item) {
      return filter === 'all' || item.level === filter || item.level === 'all';
    }

    var samples = bankSamples().filter(matchLevel);
    var indexItems = BANK_INDEX.filter(function (item) {
      return filter === 'all' || item.level === filter;
    });
    var officials = OFFICIAL_SOURCES.filter(function (item) {
      return filter === 'all' || item.level === 'all';
    });

    var sections = '';
    if (state.bankSection === 'all' || state.bankSection === 'samples') {
      sections += samplesSection(samples);
    }
    if (state.bankSection === 'all' || state.bankSection === 'index') {
      sections += indexSection(indexItems);
    }
    if (state.bankSection === 'all' || state.bankSection === 'official') {
      sections += officialSection(officials);
    }

    return '' +
      '<div class="view view-bank' + viewAnimClass(animate) + '">' +
        '<div class="navbar">' +
          '<button class="nav-btn" data-action="back">' + icon('chevronLeft', 18) + ' 返回</button>' +
          '<div class="nav-title">真题题库</div>' +
          '<div class="nav-trailing">' +
            '<button class="nav-btn" data-action="import-bank" aria-label="导入真题">' + icon('docPlus', 19) + '</button>' +
          '</div>' +
        '</div>' +
        '<div class="scroll bank-scroll">' +
          '<div class="bank-hero">' +
            '<div class="bank-hero-title">四六级真题资料</div>' +
            '<div class="bank-hero-text">内置原创模拟练习可直接阅读；历年真题以目录索引呈现。真题版权归教育部教育考试院，请通过官方或已授权渠道获取后导入，本应用不内置未授权全文。</div>' +
          '</div>' +
          '<div class="segmented bank-seg">' +
            bankChip('all', '全部', 'bank-filter', state.bankFilter) +
            bankChip('cet4', 'CET-4', 'bank-filter', state.bankFilter) +
            bankChip('cet6', 'CET-6', 'bank-filter', state.bankFilter) +
          '</div>' +
          '<div class="segmented bank-seg">' +
            bankChip('all', '全部', 'bank-section', state.bankSection) +
            bankChip('samples', '可阅读', 'bank-section', state.bankSection) +
            bankChip('index', '真题目录', 'bank-section', state.bankSection) +
            bankChip('official', '官方资料', 'bank-section', state.bankSection) +
          '</div>' +
          sections +
        '</div>' +
      '</div>';
  }

  function bankChip(value, label, action, current) {
    return '<button class="seg' + (current === value ? ' active' : '') + '" data-action="' + action +
      '" data-value="' + value + '">' + label + '</button>';
  }

  function samplesSection(samples) {
    var cards = samples.map(function (article) {
      var words = countWords(article.content);
      var isSample = article.kind === 'sample';
      var levelText = article.level === 'cet6' ? 'CET-6' : (article.level === 'cet4' ? 'CET-4' : '未分级');
      var translated = articleIsFullyTranslated(article);
      return '' +
        '<div class="bank-sample-card" role="button" tabindex="0" data-action="open-article" data-id="' + esc(article.id) + '">' +
          '<div class="bank-sample-head">' +
            '<span class="bank-tag">' + (isSample ? '模拟练习' : '我的真题') + '</span>' +
            '<span class="bank-tag ghost">' + levelText + '</span>' +
            '<span class="bank-sample-meta">' + words + ' 词' + (translated ? ' · 已翻译' : '') + '</span>' +
          '</div>' +
          '<div class="bank-sample-title">' + esc(article.title) + '</div>' +
          '<div class="bank-sample-desc">' + esc(truncate(splitParagraphs(article.content)[0] || '', 72)) + '</div>' +
        '</div>';
    }).join('');

    return '<div class="bank-section">' +
      '<div class="bank-section-title">可阅读资料<span>保留翻译 / 选词 / 语法 / 收藏 / 朗读</span></div>' +
      (cards || emptyListHtml('该级别暂无资料，可点击右上角导入真题')) +
      '</div>';
  }

  function indexSection(items) {
    if (!items.length) {
      return '<div class="bank-section"><div class="bank-section-title">历年真题目录</div>' +
        emptyListHtml('该级别暂无目录') + '</div>';
    }

    var groups = {};
    var years = [];
    items.forEach(function (item) {
      if (!groups[item.year]) {
        groups[item.year] = [];
        years.push(item.year);
      }
      groups[item.year].push(item);
    });
    years.sort(function (a, b) { return b - a; });

    var html = years.map(function (year) {
      var rows = groups[year].map(function (item) {
        return '<div class="bank-paper-row" role="button" tabindex="0" data-action="open-bank-detail" data-id="' + esc(item.id) + '">' +
          '<span class="bank-paper-title">' + esc(item.title) + '</span>' +
          '<span class="bank-paper-action">查看</span>' +
          '</div>';
      }).join('');
      return '<div class="bank-year"><div class="bank-year-label">' + year + ' 年</div>' + rows + '</div>';
    }).join('');

    return '<div class="bank-section">' +
      '<div class="bank-section-title">历年真题目录<span>仅目录 · 不含正文</span></div>' +
      html +
      '</div>';
  }

  function officialSection(items) {
    var rows = items.map(function (item) {
      return '<div class="bank-official-row" role="button" tabindex="0" data-action="open-official" data-id="' + esc(item.id) + '">' +
        '<div class="bank-official-main">' +
          '<div class="bank-official-title">' + esc(item.title) + '</div>' +
          '<div class="bank-official-desc">' + esc(item.description) + '</div>' +
        '</div>' +
        '<span class="bank-tag ghost">' + esc(item.tag) + '</span>' +
        '</div>';
    }).join('');

    return '<div class="bank-section">' +
      '<div class="bank-section-title">官方资料<span>中国教育考试网</span></div>' +
      rows +
      '</div>';
  }

  function findBankPaper(id) {
    for (var i = 0; i < BANK_INDEX.length; i += 1) {
      if (BANK_INDEX[i].id === id) return BANK_INDEX[i];
    }
    return null;
  }

  function findOfficialSource(id) {
    for (var i = 0; i < OFFICIAL_SOURCES.length; i += 1) {
      if (OFFICIAL_SOURCES[i].id === id) return OFFICIAL_SOURCES[i];
    }
    return null;
  }

  function openBankPaperSheet(item) {
    if (!item) return;
    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="action-sheet">' +
        '<div class="action-title">' + esc(item.title) + '</div>' +
        '<div class="bank-sheet-body">' +
          '<p class="tip" style="margin-top:0">真题全文的版权归教育部教育考试院所有，本应用不内置未授权的真题正文。</p>' +
          '<p class="tip">如果你已通过官方或授权渠道获得该套试卷的文本，点击「去导入」把内容粘贴进来，即可使用翻译、点词、长按组句、语法分析、收藏与朗读等全部阅读功能。</p>' +
        '</div>' +
        '<button class="action-row" data-action="import-bank-paper">我已获取，去导入</button>' +
        '<button class="action-row" data-action="open-official-syllabus">查看官方考试大纲</button>' +
        '<button class="action-row cancel" data-action="close-sheet">取消</button>' +
      '</div>');
  }

  function openOfficialSource(item) {
    if (!item) return;
    window.open(item.url, '_blank', 'noopener');
    toast('已打开官方页面');
  }

  function importView(animate) {
    return '' +
      '<div class="view view-import' + viewAnimClass(animate) + '">' +
        '<div class="navbar">' +
          '<button class="nav-btn" data-action="back">取消</button>' +
          '<div class="nav-title">导入文章</div>' +
          '<button class="nav-btn primary" data-action="save-import">开始阅读</button>' +
        '</div>' +
        '<div class="scroll import-scroll">' +
          '<div class="field">' + icon('text', 16) +
            '<input id="articleTitle" placeholder="文章标题（可选）" autocomplete="off">' +
          '</div>' +
          '<textarea id="articleContent" class="import-textarea" placeholder="粘贴或输入英语文章，建议保留段落之间的空行…"></textarea>' +
          '<div class="row-2">' +
            '<button class="soft-btn" data-action="pick-file">' + icon('folder', 16) + ' 从文件导入</button>' +
            '<button class="soft-btn" data-action="paste-text">' + icon('clipboard', 16) + ' 粘贴文本</button>' +
          '</div>' +
          '<button class="soft-btn wide" style="margin-top:10px" data-action="pick-ocr">' + icon('photo', 16) + ' 图片英文识别（OCR）</button>' +
          '<div id="ocrStatus" class="ocr-status" hidden></div>' +
          '<p class="tip">支持 .txt / .md 文件、粘贴文本，或选择图片识别英文（首次识别需联网加载引擎）。识别结果会作为文章记录保存。</p>' +
          '<input type="file" id="fileInput" accept=".txt,.md,text/plain" hidden>' +
        '</div>' +
      '</div>';
  }

  /* ==================== 弹层 ==================== */

  function openSheet(html) {
    var sheet = $id('sheet');
    sheet.innerHTML = html;
    sheet.classList.add('show');
    $id('sheetBackdrop').classList.add('show');
    sheetOpen = true;
  }

  function closeSheet() {
    $id('sheet').classList.remove('show');
    $id('sheetBackdrop').classList.remove('show');
    sheetOpen = false;
    currentWordResult = null;
    wordRequestId += 1;
    selectionRequestId += 1;
    clearTimeout(selectionTimer);
    selectionData = null;
    if (state.selection.mode) {
      state.selection = emptySelection();
      render();
    }
  }

  function openWordSheet(word) {
    if (!word) return;
    openSheet('<div class="sheet-grabber"></div><div class="progress-card" style="margin-top:4px"><span class="spinner"></span><span>正在查询释义…</span></div>');

    var requestId = ++wordRequestId;
    var local = findEntries(word);
    if (local.length) {
      var primary = local[0];
      renderWordSheet({
        word: primary.word,
        phonetic: primary.phonetic,
        meanings: local.map(function (entry) {
          return entry.level === primary.level ? entry.meaning : levelLabel(entry.level) + '：' + entry.meaning;
        }),
        source: '内置四六级词典'
      });
      return;
    }

    translateOnline(word)
      .then(function (translated) {
        if (requestId !== wordRequestId || !sheetOpen) return;
        renderWordSheet({
          word: normalizeKey(word),
          phonetic: '',
          meanings: [translated],
          source: '在线翻译'
        });
      })
      .catch(function () {
        if (requestId !== wordRequestId || !sheetOpen) return;
        renderWordSheet({
          word: normalizeKey(word),
          phonetic: '',
          meanings: ['未在四六级词库中找到，在线翻译也未成功。请检查网络后重试。'],
          source: '查询失败'
        });
      });
  }

  function renderWordSheet(result) {
    currentWordResult = result;
    var favorited = isFavorited('word', result.word);
    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="ws-head">' +
        '<div>' +
          '<div class="ws-word">' + esc(result.word) + '</div>' +
          (result.phonetic ? '<div class="ws-phonetic">' + esc(result.phonetic) + '</div>' : '') +
        '</div>' +
        '<button class="circle-btn" data-action="speak" data-text="' + esc(result.word) + '" aria-label="朗读">' + icon('speaker', 18) + '</button>' +
      '</div>' +
      '<div class="ws-card">' +
        result.meanings.map(function (meaning) {
          return '<div class="meaning-row"><span class="dot"></span><span>' + esc(meaning) + '</span></div>';
        }).join('') +
        '<div class="ws-source">释义来源：' + esc(result.source) + '</div>' +
      '</div>' +
      '<button class="soft-btn wide ' + (favorited ? 'faved' : '') + '" style="margin-top:16px" ' +
        'data-action="fav-word" data-word="' + esc(result.word) + '" ' +
        'data-meaning="' + esc(result.meanings.join('；')) + '" ' +
        'data-phonetic="' + esc(result.phonetic || '') + '">' +
        icon(favorited ? 'starOff' : 'star', 16) + ' ' + (favorited ? '已收藏（点击取消）' : '加入收藏夹') +
      '</button>');
  }

  function openSelectionSheet() {
    var selection = state.selection;
    if (!selection.mode) return;

    var text = selectionRangeText(selection.p, selection.anchor, selection.focus);
    if (!text) return;

    var words = selectionWords(selection.p, selection.anchor, selection.focus);
    selectionData = {
      text: text,
      words: words,
      wordCount: selectionWordCount(selection.p, selection.anchor, selection.focus),
      analysis: window.ECGrammar ? window.ECGrammar.analyze(text, isVerbWord) : null,
      translation: '',
      offline: false,
      loading: true
    };

    renderSelectionSheet();

    var requestId = ++selectionRequestId;
    clearTimeout(selectionTimer);
    selectionTimer = setTimeout(function () {
      translateOnline(text).then(function (translated) {
        if (requestId !== selectionRequestId || !selectionData) return;
        selectionData.translation = translated;
        selectionData.loading = false;
        renderSelectionSheet();
      }).catch(function () {
        if (requestId !== selectionRequestId || !selectionData) return;
        var gloss = offlineGloss(text);
        selectionData.translation = gloss || '在线翻译暂不可用，请稍后重试。';
        selectionData.offline = !!gloss;
        selectionData.loading = false;
        renderSelectionSheet();
      });
    }, 240);
  }

  function renderSelectionSheet() {
    var data = selectionData;
    if (!data) return;

    var analysis = data.analysis;
    var selectedCount = data.wordCount || data.words.length;
    var sentenceFaved = isFavorited('sentence', data.text);
    var wordsFaved = data.words.length > 0 && data.words.every(function (item) {
      return isFavorited('word', item.word);
    });

    var grammarHtml = '';
    if (analysis) {
      grammarHtml = '' +
        '<div class="grammar-card">' +
          '<span class="pattern-chip">' + esc(analysis.pattern) + '</span>' +
          '<div class="grammar-row"><span>主语</span><b>' + esc(analysis.subject) + '</b></div>' +
          '<div class="grammar-row"><span>谓语</span><b>' + esc(analysis.predicate) + '</b></div>' +
          '<div class="grammar-row"><span>' + esc(analysis.objectLabel || '宾语') + '</span><b>' + esc(analysis.object) + '</b></div>' +
          (analysis.adverbial ? '<div class="grammar-row"><span>状语</span><b>' + esc(analysis.adverbial) + '</b></div>' : '') +
          '<div class="grammar-note">' + esc(analysis.note || '启发式语法分析，仅供参考') + '</div>' +
        '</div>';
    }

    var translationHtml = data.loading
      ? '<div class="progress-card" style="margin-top:10px;background:transparent;padding:0"><span class="spinner"></span><span>正在翻译所选内容…</span></div>'
      : '<div class="sel-translation">' +
        (data.offline ? '<span class="offline-tag">离线逐词示意</span><br>' : '') +
        esc(data.translation || '—') + '</div>';

    var hint = selectedCount === 1
      ? '<div class="grammar-note">继续点击其他单词，即可把选中的单词连接成句子</div>'
      : '';

    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="sel-head">' +
        '<div class="sel-title">已选 ' + selectedCount + ' 个单词</div>' +
        '<button class="circle-btn sm" data-action="speak" data-text="' + esc(data.text) + '" aria-label="朗读">' + icon('speaker', 14) + '</button>' +
      '</div>' +
      '<div class="sel-sentence">' + esc(data.text) + '</div>' +
      translationHtml +
      hint +
      grammarHtml +
      '<div class="sel-actions">' +
        '<button class="soft-btn ' + (sentenceFaved ? 'faved' : '') + '" data-action="fav-sentence">' +
          icon(sentenceFaved ? 'starOff' : 'star', 15) + ' ' + (sentenceFaved ? '已收藏句子' : '收藏句子') +
        '</button>' +
        '<button class="soft-btn ' + (wordsFaved ? 'faved' : '') + '" data-action="fav-words">' +
          icon(wordsFaved ? 'starOff' : 'star', 15) + ' ' + (wordsFaved ? '单词已收藏' : '收藏这些单词') +
        '</button>' +
      '</div>' +
      '<button class="action-row cancel" data-action="close-sheet" style="margin-top:10px">完成</button>');
  }

  function openArticleMenu(article) {
    if (!article) return;
    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="action-sheet">' +
        '<div class="action-title">' + esc(article.title) + '</div>' +
        '<button class="action-row danger" data-action="delete-article" data-id="' + esc(article.id) + '">删除文章</button>' +
        '<button class="action-row cancel" data-action="close-sheet">取消</button>' +
      '</div>');
  }

  function openReaderMenu() {
    var article = currentArticle();
    var fully = articleIsFullyTranslated(article);
    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="action-sheet">' +
        '<div class="action-title">阅读设置 · ' + state.fontSize + 'pt</div>' +
        '<button class="action-row" data-action="toggle-translations">' + (state.showTranslations ? '隐藏译文' : '显示译文') + '</button>' +
        '<button class="action-row" data-action="translate">' + (fully ? '重新翻译全文' : '翻译全文') + '</button>' +
        '<button class="action-row" data-action="open-player-settings" data-mode="article">朗读整篇文章</button>' +
        '<button class="action-row cancel" data-action="close-sheet">完成</button>' +
      '</div>');
  }

  function openFavoriteSentence(item) {
    if (!item) return;
    var analysis = item.analysis || (window.ECGrammar ? window.ECGrammar.analyze(item.text, isVerbWord) : null);
    var grammarHtml = '';
    if (analysis) {
      grammarHtml = '' +
        '<div class="grammar-card">' +
          '<span class="pattern-chip">' + esc(analysis.pattern) + '</span>' +
          '<div class="grammar-row"><span>主语</span><b>' + esc(analysis.subject) + '</b></div>' +
          '<div class="grammar-row"><span>谓语</span><b>' + esc(analysis.predicate) + '</b></div>' +
          '<div class="grammar-row"><span>' + esc(analysis.objectLabel || '宾语') + '</span><b>' + esc(analysis.object) + '</b></div>' +
          (analysis.adverbial ? '<div class="grammar-row"><span>状语</span><b>' + esc(analysis.adverbial) + '</b></div>' : '') +
          '<div class="grammar-note">' + esc(analysis.note || '启发式语法分析，仅供参考') + '</div>' +
        '</div>';
    }
    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="sel-head">' +
        '<div class="sel-title">收藏的句子</div>' +
        '<button class="circle-btn sm" data-action="speak" data-text="' + esc(item.text) + '" aria-label="朗读">' + icon('speaker', 14) + '</button>' +
      '</div>' +
      '<div class="sel-sentence">' + esc(item.text) + '</div>' +
      '<div class="sel-translation">' + esc(item.translation || '暂无译文') + '</div>' +
      grammarHtml +
      '<button class="action-row danger" style="margin-top:16px" data-action="remove-fav" data-id="' + esc(item.id) + '">移出收藏夹</button>' +
      '<button class="action-row cancel" data-action="close-sheet">完成</button>');
  }

  /* ==================== 播放器 ==================== */

  function formatRemaining(ms) {
    var total = Math.max(0, Math.ceil(ms / 1000));
    var minutes = Math.floor(total / 60);
    var seconds = total % 60;
    return minutes + ':' + (seconds < 10 ? '0' + seconds : seconds);
  }

  function updatePlayerBar(snapshot) {
    var bar = $id('playerBar');
    if (!bar) return;

    if (!snapshot || !snapshot.active) {
      bar.classList.remove('show');
      bar.innerHTML = '';
      phone.classList.remove('has-player');
      return;
    }

    var remaining = snapshot.remainingMs > 0
      ? ' · ' + formatRemaining(snapshot.remainingMs) + ' 后停止'
      : '';
    var subtitle = (snapshot.index + 1) + '/' + snapshot.total +
      ' · ' + (snapshot.loop ? '循环' : '单次') +
      ' · 间隔 ' + snapshot.interval + 's' + remaining;

    bar.innerHTML = '' +
      '<div class="player-info" role="button" tabindex="0" data-action="open-player-settings" data-mode="' +
        (state.playerSettings.lastMode || (state.view === 'reader' ? 'article' : 'words')) + '">' +
        '<div class="player-title">' + esc(snapshot.label || '正在播放') + '</div>' +
        '<div class="player-sub">' + esc(subtitle) + '</div>' +
      '</div>' +
      '<button class="circle-btn sm" data-action="player-toggle" aria-label="' + (snapshot.paused ? '继续' : '暂停') + '">' +
        icon(snapshot.paused ? 'play' : 'pause', 14) + '</button>' +
      '<button class="circle-btn sm" style="background:rgba(120,120,128,.18);color:var(--text)" data-action="player-stop" aria-label="停止">' +
        icon('stop', 14) + '</button>';

    bar.classList.add('show');
    phone.classList.add('has-player');
  }

  function initPlayer() {
    if (!window.ECPlayer) return;
    window.ECPlayer.setOnChange(updatePlayerBar);
    window.ECPlayer.configure(state.playerSettings);
  }

  function openPlayerSettings(mode) {
    var pending = mode || (state.view === 'reader' ? 'article' : 'words');
    state.playerSettings.pendingMode = pending;
    var settings = state.playerSettings;
    var intervals = [0.5, 1, 2];
    var limits = [0, 5, 10, 20, 30];
    var title = pending === 'article' ? '朗读文章' : '听四六级单词';
    var items = pendingPlayerItems();
    var itemCount = items.length;
    var startValue = Math.min(Math.max(1, (settings.startIndex || 0) + 1), Math.max(1, itemCount));

    openSheet('' +
      '<div class="sheet-grabber"></div>' +
      '<div class="action-sheet">' +
        '<div class="action-title">自动播放设置 · ' + title + '</div>' +
        '<div class="setting-row">' +
          '<span class="setting-label">循环播放</span>' +
          '<button class="switch' + (settings.loop ? ' on' : '') + '" data-action="toggle-loop" aria-label="循环播放"></button>' +
        '</div>' +
        '<div class="setting-row">' +
          '<span class="setting-label">播放间隔</span>' +
          '<div class="seg-group">' +
            intervals.map(function (value) {
              return '<button class="seg' + (settings.interval === value ? ' active' : '') +
                '" data-action="set-interval" data-value="' + value + '">' + value + 's</button>';
            }).join('') +
          '</div>' +
        '</div>' +
        '<div class="setting-row">' +
          '<span class="setting-label">定时停止</span>' +
          '<div class="seg-group">' +
            limits.map(function (value) {
              return '<button class="seg' + (settings.limitMinutes === value ? ' active' : '') +
                '" data-action="set-limit" data-value="' + value + '">' + (value === 0 ? '不限' : value + '分') + '</button>';
            }).join('') +
          '</div>' +
        '</div>' +
        '<div class="play-start-row">' +
          '<span>起始位置</span>' +
          '<input id="playStart" type="range" min="1" max="' + Math.max(1, itemCount) + '" step="1" value="' + startValue + '">' +
          '<span id="playStartValue">' + startValue + '/' + Math.max(1, itemCount) + '</span>' +
        '</div>' +
        '<button class="translate-btn" style="margin-top:16px" data-action="start-player">' + icon('play', 16) + ' 开始播放</button>' +
        '<button class="action-row cancel" data-action="close-sheet">取消</button>' +
      '</div>');
  }

  function pendingPlayerItems() {
    var mode = state.playerSettings.pendingMode;
    if (mode === 'article') {
      var article = currentArticle();
      return article ? splitParagraphs(article.content) : [];
    }
    if (state.view === 'vocabulary' && state.tab === 'favorites') {
      return filteredFavorites().filter(function (item) { return item.type === 'word'; })
        .map(function (item) { return item.text; });
    }
    return filteredWords().map(function (entry) { return entry.word; });
  }

  function pendingPlayerLabel() {
    var mode = state.playerSettings.pendingMode;
    if (mode === 'article') {
      var article = currentArticle();
      return article ? article.title : '朗读文章';
    }
    if (state.tab === 'favorites') return '收藏夹单词';
    return state.tab === 'cet6' ? '六级词汇' : '四级词汇';
  }

  function startPendingPlayer() {
    state.playerSettings.lastMode = state.playerSettings.pendingMode;
    closeSheet();
    if (!window.ECPlayer || !window.ECPlayer.supported()) {
      toast('当前浏览器不支持语音朗读');
      return;
    }
    window.ECPlayer.configure(state.playerSettings);

    var items = pendingPlayerItems();
    if (!items.length) {
      toast(state.playerSettings.pendingMode === 'article' ? '请先打开一篇文章' : '当前列表没有可播放的内容');
      return;
    }
    var label = pendingPlayerLabel();
    var startIndex = Math.min(Math.max(0, state.playerSettings.startIndex || 0), Math.max(0, items.length - 1));
    if (!window.ECPlayer.start(items, label, startIndex)) {
      toast('当前列表没有可播放的内容');
      return;
    }
    var limit = state.playerSettings.limitMinutes;
    toast(limit > 0 ? '开始播放 · ' + limit + ' 分钟后自动停止' : '开始播放');
  }

  /* ==================== 行为 ==================== */

  function pickDailyWord() {
    var pool = dictionary.cet4.concat(dictionary.cet6);
    if (!pool.length) {
      state.dailyWord = null;
      return;
    }
    var previous = state.dailyWord ? normalizeKey(state.dailyWord.word) : '';
    var next = pool[Math.floor(Math.random() * pool.length)];
    var guard = 0;
    while (pool.length > 1 && normalizeKey(next.word) === previous && guard < 12) {
      next = pool[Math.floor(Math.random() * pool.length)];
      guard += 1;
    }
    state.dailyWord = next;
  }

  function navigate(view) {
    if (state.view !== view) state.navStack.push(state.view);
    state.view = view;
    state.error = '';
    state.translating = false;
    render({ animate: true });
  }

  function goBack() {
    var previous = state.navStack.pop() || 'home';
    state.view = previous;
    state.error = '';
    state.translating = false;
    if (previous !== 'reader') state.articleId = null;
    render({ animate: true });
  }

  function openArticle(id) {
    var article = findArticle(id);
    if (!article) return;
    state.articleId = id;
    state.selection = emptySelection();
    navigate('reader');
  }

  function openTab(tab) {
    state.tab = tab;
    state.search = '';
    navigate('vocabulary');
  }

  function switchTab(tab) {
    state.tab = tab;
    state.search = '';
    render();
  }

  function updateVocabList() {
    var list = $id('vocabList');
    if (!list) return;
    var isFavorites = state.tab === 'favorites';
    list.innerHTML = isFavorites ? favoriteRowsHtml() : vocabRowsHtml();
    var countEl = $id('vocabCount');
    if (countEl) {
      countEl.textContent = isFavorites
        ? '共 ' + filteredFavorites().length + ' 条收藏'
        : '共 ' + filteredWords().length + ' 个单词';
    }
  }

  function saveImportedArticle() {
    var titleEl = $id('articleTitle');
    var contentEl = $id('articleContent');
    var title = titleEl ? titleEl.value.trim() : '';
    var content = contentEl ? contentEl.value.trim() : '';
    if (!content) {
      toast('请先输入或导入文章内容');
      return;
    }
    var isBank = state.importContext === 'bank';
    var isOcr = state.importContext === 'ocr';
    var article = {
      id: uid(),
      title: title || deriveTitle(content),
      content: content,
      createdAt: Date.now(),
      translations: {},
      bank: isBank,
      kind: isBank ? 'imported' : (isOcr ? 'ocr' : 'article'),
      level: isBank ? (state.bankFilter === 'cet6' ? 'cet6' : 'cet4') : ''
    };
    state.importContext = 'article';
    state.articles.unshift(article);
    state.articleId = article.id;
    state.view = 'reader';
    state.error = '';
    state.translating = false;
    persist();
    render();
    toast(isBank
      ? '已加入真题题库，可直接开始阅读'
      : (isOcr ? '图片识别记录已保存，可直接开始阅读' : '文章已导入，可点击「一键翻译全文」'));
  }

  function deriveTitle(content) {
    var lines = String(content).split(/\r?\n/);
    for (var i = 0; i < lines.length; i += 1) {
      var line = lines[i].trim();
      if (line) return truncate(line, 28);
    }
    return '未命名文章';
  }

  function deleteArticle(id) {
    state.articles = state.articles.filter(function (article) { return article.id !== id; });
    if (state.articleId === id) state.articleId = null;
    persist();
    closeSheet();
    render();
    toast('已删除文章');
  }

  function resetSamples() {
    var bankArticles = state.articles.filter(function (article) { return article.bank; });
    state.articles = bankArticles.concat(JSON.parse(JSON.stringify(SAMPLE_ARTICLES)));
    state.articleId = null;
    state.view = 'home';
    state.navStack = [];
    state.error = '';
    persist();
    render();
    toast('已恢复示例文章');
  }

  function ensureBankSamples() {
    BANK_SAMPLE_ARTICLES.forEach(function (sample) {
      var exists = state.articles.some(function (article) { return article.id === sample.id; });
      if (!exists) {
        state.articles.push(JSON.parse(JSON.stringify(sample)));
      }
    });
  }

  function toggleWordFavorite(word, meaning, phonetic) {
    if (!word) return;
    if (isFavorited('word', word)) {
      var key = normalizeKey(word);
      state.favorites = state.favorites.filter(function (item) {
        return !(item.type === 'word' && normalizeKey(item.text) === key);
      });
      persist();
      toast('已移出收藏夹');
    } else {
      addFavorite({ type: 'word', text: word, translation: meaning || '暂无释义', phonetic: phonetic || '' });
      toast('已加入收藏夹');
    }
    if (currentWordResult) {
      renderWordSheet(currentWordResult);
    }
    render();
  }

  function toggleSentenceFavorite() {
    var data = selectionData;
    if (!data || !data.text) return;
    if (isFavorited('sentence', data.text)) {
      var target = data.text.trim().toLowerCase();
      state.favorites = state.favorites.filter(function (item) {
        return !(item.type === 'sentence' && String(item.text || '').trim().toLowerCase() === target);
      });
      persist();
      toast('已取消收藏句子');
    } else {
      addFavorite({
        type: 'sentence',
        text: data.text,
        translation: data.translation || '',
        analysis: data.analysis
      });
      toast('已收藏句子');
    }
    renderSelectionSheet();
    render();
  }

  function addSelectionWordsToFavorites() {
    var data = selectionData;
    if (!data || !data.words.length) return;
    var added = 0;
    data.words.forEach(function (item) {
      if (addFavorite({
        type: 'word',
        text: item.word,
        translation: item.meaning,
        phonetic: item.phonetic
      })) {
        added += 1;
      }
    });
    toast(added > 0 ? '已收藏 ' + added + ' 个单词' : '选中的单词已在收藏夹中');
    renderSelectionSheet();
    render();
  }

  function handleTranslate() {
    var article = currentArticle();
    if (!article || state.translating) return;

    var paragraphs = splitParagraphs(article.content);
    if (!paragraphs.length) {
      toast('文章内容为空');
      return;
    }

    if (articleIsFullyTranslated(article)) {
      article.translations = {};
    }

    state.translating = true;
    state.error = '';
    state.progress = { done: 0, total: paragraphs.length };
    render();

    var chain = Promise.resolve();
    paragraphs.forEach(function (paragraph, index) {
      chain = chain.then(function () {
        if (!state.translating) return null;
        if (article.translations && article.translations[index]) {
          state.progress.done += 1;
          return null;
        }
        return translateParagraph(paragraph).then(function (translated) {
          if (!article.translations) article.translations = {};
          article.translations[index] = translated;
          article.translatedAt = Date.now();
          state.progress.done += 1;
          persist();
          render();
          return null;
        });
      });
    });

    chain.then(function () {
      if (!state.translating) return;
      state.translating = false;
      article.translatedAt = Date.now();
      persist();
      render();
      toast('全文翻译完成');
    }).catch(function (error) {
      state.translating = false;
      state.error = (error && error.message) ? error.message : '翻译失败，请稍后重试。';
      persist();
      render();
    });
  }

  function readFile(file) {
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      toast('文件过大（超过 2MB）');
      return;
    }
    if (typeof file.text === 'function') {
      file.text().then(function (text) {
        fillImportForm(text, file.name);
      }).catch(function () {
        toast('读取文件失败，请确认是纯文本格式');
      });
      return;
    }
    var reader = new FileReader();
    reader.onload = function () {
      fillImportForm(String(reader.result || ''), file.name);
    };
    reader.onerror = function () {
      toast('读取文件失败，请确认是纯文本格式');
    };
    reader.readAsText(file, 'utf-8');
  }

  function fillImportForm(text, fileName) {
    var contentEl = $id('articleContent');
    if (!contentEl) return;
    contentEl.value = text;
    var titleEl = $id('articleTitle');
    if (titleEl && !titleEl.value.trim()) {
      titleEl.value = String(fileName || '').replace(/\.[^.]+$/, '');
    }
    toast('已读取文件内容');
  }

  function pasteText() {
    if (!navigator.clipboard || !navigator.clipboard.readText) {
      toast('浏览器不支持读取剪贴板，请直接 Ctrl+V 粘贴到文本框');
      return;
    }
    navigator.clipboard.readText().then(function (text) {
      if (!text) {
        toast('剪贴板为空');
        return;
      }
      var contentEl = $id('articleContent');
      if (contentEl) contentEl.value = text;
      toast('已粘贴剪贴板内容');
    }).catch(function () {
      toast('浏览器禁止读取剪贴板，请直接 Ctrl+V 粘贴到文本框');
    });
  }

  function toast(message) {
    var el = $id('toast');
    if (!el) return;
    el.textContent = message;
    el.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      el.classList.remove('show');
    }, 2200);
  }

  function tickClock() {
    var el = $id('clock');
    if (!el) return;
    var now = new Date();
    el.textContent = now.getHours() + ':' + String(now.getMinutes()).padStart(2, '0');
  }

  /* ==================== 选择交互 ==================== */

  function beginSelection(p, i) {
    state.selection = { mode: true, p: p, anchor: i, focus: i };
    render();
    openSelectionSheet();
    if (navigator.vibrate) {
      try { navigator.vibrate(12); } catch (err) {}
    }
  }

  function extendSelection(p, i) {
    var selection = state.selection;
    if (!selection.mode || selection.p !== p) {
      state.selection = { mode: true, p: p, anchor: i, focus: i };
    } else {
      selection.focus = i;
    }
    render();
    openSelectionSheet();
  }

  function handleWordTap(p, i, word) {
    if (state.selection.mode) {
      extendSelection(p, i);
      return;
    }
    openWordSheet(word);
  }

  function bindPointerSelection() {
    document.addEventListener('pointerdown', function (event) {
      if (state.view !== 'reader' || state.readMode) return;
      var el = event.target.closest ? event.target.closest('.word') : null;
      if (!el) return;

      pressState = {
        p: Number(el.dataset.p),
        i: Number(el.dataset.i),
        word: el.dataset.w,
        x: event.clientX,
        y: event.clientY,
        longPress: false,
        cancelled: false
      };

      clearTimeout(pressTimer);
      pressTimer = setTimeout(function () {
        if (!pressState || pressState.cancelled) return;
        pressState.longPress = true;
        beginSelection(pressState.p, pressState.i);
      }, 500);
    }, { passive: true });

    document.addEventListener('pointermove', function (event) {
      if (!pressState) return;
      if (Math.abs(event.clientX - pressState.x) > 8 || Math.abs(event.clientY - pressState.y) > 8) {
        pressState.cancelled = true;
        clearTimeout(pressTimer);
      }
    }, { passive: true });

    document.addEventListener('pointerup', function () {
      clearTimeout(pressTimer);
      var press = pressState;
      pressState = null;
      if (!press || press.cancelled || press.longPress) return;
      handleWordTap(press.p, press.i, press.word);
    }, { passive: true });

    document.addEventListener('pointercancel', function () {
      clearTimeout(pressTimer);
      if (pressState) pressState.cancelled = true;
    }, { passive: true });
  }

  /* ==================== 事件 ==================== */

  function handleAction(action, el) {
    switch (action) {
      case 'open-appearance':
        openAppearanceSheet();
        break;
      case 'set-icon-style':
        appearance.icon = {
          type: 'builtin',
          style: el.dataset.style || 'blue',
          image: ''
        };
        persistAppearance();
        render();
        if (sheetOpen && $id('wallpaperOpacity')) openAppearanceSheet();
        break;
      case 'pick-icon':
        var iconFileInput = $id('iconInput');
        if (iconFileInput) iconFileInput.click();
        break;
      case 'clear-icon':
        appearance.icon = { type: 'builtin', style: 'blue', image: '' };
        persistAppearance();
        openAppearanceSheet();
        toast('已恢复默认图标');
        break;
      case 'pick-ocr':
        var ocrFileInput = $id('ocrInput');
        if (ocrFileInput) ocrFileInput.click();
        break;
      case 'export-package':
        exportPackage();
        break;
      case 'open-viewer':
        window.open('viewer.html', '_blank', 'noopener');
        break;
      case 'open-backup':
        navigate('backup');
        break;
      case 'open-backup-console':
        window.open('backup-console.html', '_blank', 'noopener');
        break;
      case 'pick-backup-files':
        var backupInput = $id('backupInput');
        if (backupInput) backupInput.click();
        break;
      case 'save-backup-settings':
        saveBackupSettings();
        break;
      case 'start-backup':
        startBackup();
        break;
      case 'clear-backup-pending':
        state.backup.pending = [];
        render();
        toast('已清空待备份文件');
        break;
      case 'open-backup-record':
        var recordId = el.dataset.id;
        var backupRecord = null;
        for (var r = 0; r < state.backup.records.length; r += 1) {
          if (state.backup.records[r].id === recordId) {
            backupRecord = state.backup.records[r];
            break;
          }
        }
        openBackupRecordSheet(backupRecord);
        break;
      case 'download-icon':
        downloadAppIcon();
        break;
      case 'open-shortcuts-guide':
        openShortcutsGuide();
        break;
      case 'open-shortcuts-app':
        toast('该操作在 iOS App 内可打开「快捷指令」；桌面浏览器无法打开。');
        break;
      case 'pick-launch':
        var launchFileInput = $id('launchInput');
        if (launchFileInput) launchFileInput.click();
        break;
      case 'clear-launch':
        appearance.launch.image = '';
        appearance.launch.type = '';
        persistAppearance();
        if (sheetOpen && $id('launchSize')) openAppearanceSheet();
        toast('已清除启动动画');
        break;
      case 'set-launch-fit':
        appearance.launch.fit = el.dataset.value === 'cover' ? 'cover' : 'contain';
        persistAppearance();
        if (sheetOpen && $id('launchSize')) openAppearanceSheet();
        break;
      case 'toggle-launch':
        appearance.launch.enabled = !appearance.launch.enabled;
        persistAppearance();
        if (sheetOpen && $id('launchSize')) openAppearanceSheet();
        toast(appearance.launch.enabled ? '已开启启动动画' : '已关闭启动动画');
        break;
      case 'preview-launch':
        closeSheet();
        playLaunchScreen(true);
        break;
      case 'pick-wallpaper':
        imageTarget = 'wallpaper';
        var wallpaperInput = $id('wallpaperInput');
        if (wallpaperInput) wallpaperInput.click();
        break;
      case 'clear-wallpaper':
        appearance.wallpaper.image = '';
        applyWallpaper();
        persistAppearance();
        openAppearanceSheet();
        toast('已移除壁纸');
        break;
      case 'pick-skin':
        imageTarget = pendingSkinKey;
        var skinInput = $id('skinInput');
        if (skinInput) skinInput.click();
        break;
      case 'clear-skin':
        if (pendingSkinKey) {
          delete appearance.skins[pendingSkinKey];
          persistAppearance();
          applySkins();
          openSkinSheet(pendingSkinKey, pendingSkinLabel);
          toast('已清除组件图案');
        }
        break;
      case 'start-skin-editing':
        enterSkinEditing();
        break;
      case 'exit-skin-editing':
        exitSkinEditing();
        break;
      case 'reset-appearance':
        resetAppearance();
        break;
      case 'back':
        goBack();
        break;
      case 'open-import':
        state.importContext = 'article';
        navigate('import');
        break;
      case 'import-bank':
      case 'import-bank-paper':
        closeSheet();
        state.importContext = 'bank';
        navigate('import');
        break;
      case 'open-bank':
        navigate('bank');
        break;
      case 'bank-filter':
        state.bankFilter = el.dataset.value || 'all';
        render();
        break;
      case 'bank-section':
        state.bankSection = el.dataset.value || 'all';
        render();
        break;
      case 'open-bank-detail':
        openBankPaperSheet(findBankPaper(el.dataset.id));
        break;
      case 'open-official':
        openOfficialSource(findOfficialSource(el.dataset.id));
        break;
      case 'open-official-syllabus':
        closeSheet();
        openOfficialSource(findOfficialSource('official-syllabus'));
        break;
      case 'save-import':
        saveImportedArticle();
        break;
      case 'open-tab':
        openTab(el.dataset.tab || 'cet4');
        break;
      case 'switch-tab':
        switchTab(el.dataset.tab || 'cet4');
        break;
      case 'open-favorites':
        openTab('favorites');
        break;
      case 'open-article':
        openArticle(el.dataset.id);
        break;
      case 'article-menu':
        openArticleMenu(findArticle(el.dataset.id));
        break;
      case 'delete-article':
        deleteArticle(el.dataset.id);
        break;
      case 'translate':
        closeSheet();
        handleTranslate();
        break;
      case 'toggle-translations':
        state.showTranslations = !state.showTranslations;
        persist();
        closeSheet();
        render();
        break;
      case 'font-dec':
        changeFont(-1);
        break;
      case 'font-inc':
        changeFont(1);
        break;
      case 'toggle-theme':
        toggleTheme();
        break;
      case 'toggle-read-mode':
        toggleReadMode();
        break;
      case 'reader-menu':
        openReaderMenu();
        break;
      case 'speak':
        speak(el.dataset.text || '');
        break;
      case 'open-word':
        openWordSheet(el.dataset.word || '');
        break;
      case 'shuffle-word':
        pickDailyWord();
        render();
        break;
      case 'fav-word':
        toggleWordFavorite(el.dataset.word, el.dataset.meaning, el.dataset.phonetic);
        break;
      case 'fav-sentence':
        toggleSentenceFavorite();
        break;
      case 'fav-words':
        addSelectionWordsToFavorites();
        break;
      case 'open-fav-sentence': {
        var item = null;
        for (var i = 0; i < state.favorites.length; i += 1) {
          if (state.favorites[i].id === el.dataset.id) {
            item = state.favorites[i];
            break;
          }
        }
        openFavoriteSentence(item);
        break;
      }
      case 'remove-fav':
        removeFavoriteById(el.dataset.id);
        closeSheet();
        render();
        toast('已移出收藏夹');
        break;
      case 'pick-file':
        var input = $id('fileInput');
        if (input) input.click();
        break;
      case 'paste-text':
        pasteText();
        break;
      case 'clear-search':
        state.search = '';
        render();
        break;
      case 'close-sheet':
        closeSheet();
        break;
      case 'reset-demo':
        resetSamples();
        break;
      case 'open-player-settings':
        openPlayerSettings(el.dataset.mode);
        break;
      case 'toggle-loop':
        state.playerSettings.loop = !state.playerSettings.loop;
        persist();
        openPlayerSettings(state.playerSettings.pendingMode);
        break;
      case 'set-interval':
        state.playerSettings.interval = Number(el.dataset.value) || 1;
        persist();
        openPlayerSettings(state.playerSettings.pendingMode);
        break;
      case 'set-limit':
        state.playerSettings.limitMinutes = Number(el.dataset.value) || 0;
        persist();
        openPlayerSettings(state.playerSettings.pendingMode);
        break;
      case 'start-player':
        startPendingPlayer();
        break;
      case 'player-toggle':
        if (!window.ECPlayer) return;
        var snap = window.ECPlayer.snapshot();
        if (snap.paused) window.ECPlayer.resume();
        else window.ECPlayer.pause();
        break;
      case 'player-stop':
        if (window.ECPlayer) window.ECPlayer.stop();
        toast('已停止播放');
        break;
      default:
        break;
    }
  }

  function bindEvents() {
    document.addEventListener('click', function (event) {
      if (!appearance.editing) return;
      if (event.target.closest && event.target.closest('#sheet')) return;
      var skinEl = event.target.closest ? event.target.closest('[data-skin]') : null;
      if (!skinEl) return;
      event.preventDefault();
      event.stopPropagation();
      openSkinSheet(skinEl.getAttribute('data-skin'), skinEl.getAttribute('data-skin-label') || '组件');
    }, true);

    document.addEventListener('click', function (event) {
      var el = event.target.closest ? event.target.closest('[data-action]') : null;
      if (!el) return;
      if (el.tagName === 'DIV' && event.preventDefault) event.preventDefault();
      handleAction(el.dataset.action, el);
    });

    document.addEventListener('input', function (event) {
      if (event.target.id === 'playStart') {
        var playStartValue = Math.max(1, Number(event.target.value) || 1);
        state.playerSettings.startIndex = playStartValue - 1;
        var playStartLabel = $id('playStartValue');
        if (playStartLabel) playStartLabel.textContent = playStartValue + '/' + (event.target.max || '1');
        return;
      }

      if (event.target.id === 'launchSize') {
        appearance.launch.size = Math.min(100, Math.max(20, Number(event.target.value) || 60));
        persistAppearance();
        var launchSizeLabel = $id('launchSizeValue');
        if (launchSizeLabel) launchSizeLabel.textContent = Math.round(appearance.launch.size) + '%';
        return;
      }

      if (event.target.id === 'launchDuration') {
        appearance.launch.duration = Math.min(5, Math.max(0.5, (Number(event.target.value) || 22) / 10));
        persistAppearance();
        var launchDurationLabel = $id('launchDurationValue');
        if (launchDurationLabel) launchDurationLabel.textContent = appearance.launch.duration.toFixed(1) + 's';
        return;
      }

      if (event.target.id === 'wallpaperOpacity') {
        var wallpaperValue = Math.min(1, Math.max(0, Number(event.target.value) / 100));
        appearance.wallpaper.opacity = wallpaperValue;
        applyWallpaper();
        persistAppearance();
        var wallpaperLabel = $id('wallpaperOpacityValue');
        if (wallpaperLabel) wallpaperLabel.textContent = Math.round(wallpaperValue * 100) + '%';
        return;
      }

      if (event.target.id === 'skinOpacity') {
        if (!pendingSkinKey || !appearance.skins[pendingSkinKey]) return;
        var skinValue = Math.min(1, Math.max(0, Number(event.target.value) / 100));
        appearance.skins[pendingSkinKey].opacity = skinValue;
        updateSkinsFor(pendingSkinKey);
        persistAppearance();
        var skinLabel = $id('skinOpacityValue');
        if (skinLabel) skinLabel.textContent = Math.round(skinValue * 100) + '%';
        return;
      }

      if (event.target.id !== 'vocabSearch') return;
      state.search = event.target.value;
      updateVocabList();
      var clear = $id('searchClear');
      if (clear) clear.style.visibility = state.search ? 'visible' : 'hidden';
    });

    document.addEventListener('change', function (event) {
      if (event.target.id === 'wallpaperInput' || event.target.id === 'skinInput') {
        var picked = event.target.files && event.target.files[0];
        var target = imageTarget;
        event.target.value = '';
        imageTarget = '';
        if (picked && target) handleImageFile(picked, target);
        return;
      }

      if (event.target.id === 'launchInput') {
        var launchPicked = event.target.files && event.target.files[0];
        event.target.value = '';
        if (launchPicked) handleLaunchFile(launchPicked);
        return;
      }

      if (event.target.id === 'iconInput') {
        var iconPicked = event.target.files && event.target.files[0];
        event.target.value = '';
        if (iconPicked) handleIconFile(iconPicked);
        return;
      }

      if (event.target.id === 'ocrInput') {
        var ocrPicked = event.target.files && event.target.files[0];
        event.target.value = '';
        if (ocrPicked) handleOcrFile(ocrPicked);
        return;
      }

      if (event.target.id === 'backupInput') {
        var backupFiles = Array.prototype.slice.call(event.target.files || []);
        event.target.value = '';
        handleBackupFiles(backupFiles);
        return;
      }

      if (event.target.id !== 'fileInput') return;
      var file = event.target.files && event.target.files[0];
      event.target.value = '';
      readFile(file);
    });

    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape' && sheetOpen) {
        closeSheet();
        return;
      }
      if (event.key === 'Enter' || event.key === ' ') {
        var el = event.target.closest ? event.target.closest('[role="button"]') : null;
        if (el && el === event.target) {
          event.preventDefault();
          el.click();
        }
      }
    });

    $id('sheetBackdrop').addEventListener('click', closeSheet);
    bindPointerSelection();
  }

  /* ==================== 启动 ==================== */

  function init() {
    initDictionary();

    var saved = loadJSON(STORAGE_KEY, null);
    if (saved && Array.isArray(saved.articles)) {
      state.articles = saved.articles;
      state.favorites = Array.isArray(saved.favorites) ? saved.favorites : [];
      if (!state.favorites.length && Array.isArray(saved.wordbook) && saved.wordbook.length) {
        state.favorites = saved.wordbook.map(function (item) {
          return {
            id: item.id || uid(),
            type: 'word',
            text: item.word,
            translation: item.meaning || '',
            phonetic: item.phonetic || '',
            analysis: null,
            addedAt: item.at || Date.now()
          };
        });
      }
      state.fontSize = saved.fontSize || 17;
      state.showTranslations = saved.showTranslations !== false;
      state.readMode = !!saved.readMode;
      state.theme = saved.theme === 'dark' ? 'dark' : (saved.theme === 'light' ? 'light' : initialTheme());
      if (saved.playerSettings) {
        state.playerSettings.loop = saved.playerSettings.loop !== false;
        state.playerSettings.interval = saved.playerSettings.interval || 1;
        state.playerSettings.limitMinutes = saved.playerSettings.limitMinutes || 0;
        state.playerSettings.pendingMode = saved.playerSettings.pendingMode || 'words';
        state.playerSettings.lastMode = saved.playerSettings.lastMode || 'words';
      }
    } else {
      state.articles = JSON.parse(JSON.stringify(SAMPLE_ARTICLES));
      state.theme = initialTheme();
    }

    if (!state.articles.length) {
      state.articles = JSON.parse(JSON.stringify(SAMPLE_ARTICLES));
    }

    ensureBankSamples();

    loadBackup();
    loadAppearance();
    applyWallpaper();
    applyTheme(state.theme, false);
    pickDailyWord();
    tickClock();
    setInterval(tickClock, 30000);
    bindEvents();
    initPlayer();
    render();
    playLaunchScreen(false);
  }

  init();
})();