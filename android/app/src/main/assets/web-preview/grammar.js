(function (global) {
  'use strict';

  var BE = ['am', 'is', 'are', 'was', 'were', 'be', 'been', 'being'];
  var AUX = ['do', 'does', 'did', 'have', 'has', 'had', 'will', 'would', 'shall', 'should', 'can', 'could', 'may', 'might', 'must', 'ought'];
  var PREPOSITIONS = ['in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'of', 'about', 'into', 'onto', 'over', 'under', 'between', 'among', 'through', 'during', 'without', 'against', 'toward', 'towards', 'upon', 'within', 'across', 'behind', 'beside', 'beyond', 'after', 'before', 'since', 'until', 'till', 'despite', 'like', 'as', 'than', 'around', 'near', 'off', 'out', 'up', 'down'];
  var CONJUNCTIONS = ['and', 'but', 'or', 'so', 'because', 'although', 'though', 'while', 'if', 'when', 'unless', 'since', 'as', 'that', 'which', 'who', 'whom', 'whose', 'where', 'whether'];
  var ADVERBS = ['often', 'always', 'usually', 'never', 'sometimes', 'also', 'just', 'still', 'even', 'only', 'really', 'already', 'seldom', 'rarely', 'frequently', 'generally', 'normally', 'perhaps', 'maybe', 'probably', 'certainly', 'actually', 'finally', 'suddenly', 'recently', 'lately'];
  var PRONOUNS = ['i', 'you', 'he', 'she', 'it', 'we', 'they', 'who', 'there', 'this', 'that', 'these', 'those', 'everyone', 'everybody', 'someone', 'somebody', 'nobody', 'nothing', 'everything', 'something', 'anything'];

  var COMMON_VERBS = [
    'accept', 'achieve', 'add', 'admit', 'affect', 'agree', 'allow', 'answer', 'appear', 'apply',
    'argue', 'arrive', 'ask', 'avoid', 'become', 'begin', 'believe', 'belong', 'borrow', 'break',
    'bring', 'build', 'buy', 'call', 'carry', 'cause', 'change', 'choose', 'claim', 'climb',
    'close', 'come', 'compare', 'complete', 'consider', 'contain', 'continue', 'control', 'create', 'cut',
    'decide', 'deliver', 'demand', 'describe', 'design', 'develop', 'die', 'discover', 'discuss', 'draw',
    'drive', 'eat', 'encourage', 'enjoy', 'establish', 'expect', 'explain', 'express', 'face', 'fail',
    'fall', 'feel', 'fight', 'fill', 'find', 'finish', 'focus', 'follow', 'forget', 'form',
    'gain', 'get', 'give', 'go', 'grow', 'guess', 'handle', 'happen', 'hear', 'help',
    'hold', 'hope', 'identify', 'ignore', 'imagine', 'improve', 'include', 'increase', 'indicate', 'influence',
    'inform', 'insist', 'involve', 'join', 'keep', 'know', 'lead', 'learn', 'leave', 'let',
    'like', 'live', 'look', 'lose', 'love', 'make', 'manage', 'mean', 'meet', 'mention',
    'move', 'need', 'notice', 'offer', 'open', 'order', 'pass', 'pay', 'perform', 'plan',
    'play', 'prefer', 'prepare', 'present', 'prevent', 'produce', 'protect', 'prove', 'provide', 'publish',
    'pull', 'push', 'put', 'raise', 'reach', 'read', 'realize', 'receive', 'recognize', 'recommend',
    'reduce', 'refuse', 'remain', 'remember', 'remove', 'repeat', 'replace', 'require', 'respond', 'rest',
    'return', 'reveal', 'rise', 'run', 'save', 'say', 'see', 'seem', 'sell', 'send',
    'serve', 'set', 'share', 'show', 'sit', 'sleep', 'solve', 'speak', 'spend', 'stand',
    'start', 'stay', 'stop', 'study', 'succeed', 'suggest', 'support', 'suppose', 'take', 'talk',
    'teach', 'tell', 'tend', 'test', 'think', 'throw', 'touch', 'travel', 'treat', 'try',
    'turn', 'understand', 'use', 'visit', 'wait', 'walk', 'want', 'watch', 'wear', 'win',
    'wish', 'work', 'worry', 'write'
  ];

  function splitWords(text) {
    var cleaned = String(text || '').replace(/[^A-Za-z'’\-\s]/g, ' ');
    return cleaned.split(/\s+/).filter(Boolean);
  }

  function isBe(word) {
    return BE.indexOf(word) >= 0;
  }

  function detectVerb(word, lookup) {
    var value = String(word || '').toLowerCase();
    if (isBe(value)) return 'be';
    if (AUX.indexOf(value) >= 0) return 'aux';
    if (COMMON_VERBS.indexOf(value) >= 0) return 'verb';
    if (typeof lookup === 'function' && lookup(value)) return 'verb';
    if (/ied$/.test(value) && value.length > 4) return 'verb';
    if (/ed$/.test(value) && value.length > 3) return 'verb';
    if (/ing$/.test(value) && value.length > 4) return 'verb';
    return '';
  }

  function splitSubject(input) {
    var body = input.slice();
    var adverbial = [];

    while (body.length && (CONJUNCTIONS.indexOf(body[0].toLowerCase()) >= 0 || PREPOSITIONS.indexOf(body[0].toLowerCase()) >= 0)) {
      adverbial.push(body.shift());
    }

    var kept = [];
    for (var i = 0; i < body.length; i += 1) {
      if (ADVERBS.indexOf(body[i].toLowerCase()) >= 0) {
        adverbial.push(body[i]);
      } else {
        kept.push(body[i]);
      }
    }

    return {
      subject: kept.join(' '),
      adverbial: adverbial.join(' ')
    };
  }

  function result(pattern, subject, predicate, objectLabel, object, adverbial, note, complete, wordCount) {
    return {
      pattern: pattern,
      subject: subject || '（省略）',
      predicate: predicate || '—',
      objectLabel: objectLabel || '宾语',
      object: object || '—',
      adverbial: adverbial || '',
      note: note || '',
      complete: complete !== false,
      wordCount: wordCount || 0
    };
  }

  function analyze(text, lookup) {
    var words = splitWords(text);
    var lower = words.map(function (word) { return word.toLowerCase(); });
    var count = words.length;

    if (!count) return null;
    if (count === 1) {
      return result('单词 / 片段', words[0], '—', '释义', '—', '', '选择一个完整的句子片段可以获得语法分析', false, count);
    }

    var verbIndex = -1;
    var verbType = '';

    for (var i = 0; i < lower.length; i += 1) {
      var type = detectVerb(lower[i], lookup);
      if (!type) continue;
      if (i === 0 && /ing$/.test(lower[i]) && i + 1 < lower.length && isBe(lower[i + 1])) {
        continue;
      }
      verbIndex = i;
      verbType = type;
      break;
    }

    if (lower[0] === 'there' && verbIndex > 0) {
      return result(
        'There be 句型（存在句）',
        'there（形式主语）',
        words.slice(1, verbIndex + 1).join(' '),
        '真实主语',
        words.slice(verbIndex + 1).join(' ') || '—',
        '',
        '',
        true,
        count
      );
    }

    if (verbIndex === 0) {
      return result(
        '祈使句 / 无主语',
        '（省略）',
        words[0],
        '宾语 / 补语',
        words.slice(1).join(' ') || '—',
        '',
        '句首为动词，可能是祈使句',
        true,
        count
      );
    }

    if (verbIndex < 0) {
      return result(
        '未识别谓语',
        words.join(' '),
        '—',
        '宾语 / 表语',
        '—',
        '',
        '可能是名词短语、标题或省略结构',
        false,
        count
      );
    }

    var subjectParts = splitSubject(words.slice(0, verbIndex));
    var predicateWords = [words[verbIndex]];
    var nextIndex = verbIndex + 1;

    if ((verbType === 'aux' || verbType === 'be') && nextIndex < words.length) {
      var nextType = detectVerb(lower[nextIndex], lookup);
      if (nextType && !isAux(lower[nextIndex])) {
        predicateWords.push(words[nextIndex]);
        nextIndex += 1;
      }
    }

    var rest = words.slice(nextIndex);
    var restLower = lower.slice(nextIndex);

    if (isBe(lower[verbIndex]) && rest.length) {
      return result(
        '主系表（SVP）',
        subjectParts.subject,
        predicateWords.join(' '),
        '表语',
        rest.join(' '),
        subjectParts.adverbial,
        '',
        true,
        count
      );
    }

    if (!rest.length) {
      return result(
        '主谓（SV）',
        subjectParts.subject,
        predicateWords.join(' '),
        '宾语',
        '—',
        subjectParts.adverbial,
        '',
        true,
        count
      );
    }

    var prepIndex = -1;
    for (var j = 0; j < restLower.length; j += 1) {
      if (PREPOSITIONS.indexOf(restLower[j]) >= 0) {
        prepIndex = j;
        break;
      }
    }

    var objectWords = prepIndex >= 0 ? rest.slice(0, prepIndex) : rest;
    var adverbial = [subjectParts.adverbial];
    if (prepIndex >= 0) adverbial.push(rest.slice(prepIndex).join(' '));

    if (!objectWords.length) {
      return result(
        '主谓（SV）+ 状语',
        subjectParts.subject,
        predicateWords.join(' '),
        '宾语',
        '—',
        adverbial.filter(Boolean).join(' '),
        '动词后的介词短语作状语',
        true,
        count
      );
    }

    return result(
      '主谓宾（SVO）',
      subjectParts.subject,
      predicateWords.join(' '),
      '宾语',
      objectWords.join(' '),
      adverbial.filter(Boolean).join(' '),
      '',
      true,
      count
    );
  }

  global.ECGrammar = {
    analyze: analyze,
    detectVerb: detectVerb
  };
})(window);