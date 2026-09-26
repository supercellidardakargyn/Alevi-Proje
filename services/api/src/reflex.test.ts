import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { decideReflex, evaluateReport, ReflexVerdict } from './services/reflex.js';

/**
 * Jev cagrisi yapilmaz. Reflex kapaliyken (env yok) degerlendirme guvenli
 * sekilde null doner; karar kurali saf fonksiyon olarak test edilir.
 */
describe('reflex: kapaliyken guvenli davranis', () => {
  it('returns null when the eval gateway is not configured', async () => {
    assert.equal(await evaluateReport('Sebep: SPAM\nDetay: reklam mesaji'), null);
  });

  it('returns null on empty input', async () => {
    assert.equal(await evaluateReport('   '), null);
  });
});

describe('reflex: karar kurali', () => {
  const base: ReflexVerdict = { severity: 0, severityConfidence: 0, category: 'other', actionable: 0 };

  it('auto-suspends only on severe, confident and actionable verdicts', () => {
    assert.equal(
      decideReflex({ ...base, severity: 4, severityConfidence: 0.9, actionable: 0.9 }),
      'auto-suspend'
    );
    assert.equal(
      decideReflex({ ...base, severity: 3, severityConfidence: 0.75, actionable: 0.7 }),
      'auto-suspend'
    );
  });

  it('does not auto-suspend on low confidence or low actionability', () => {
    assert.equal(
      decideReflex({ ...base, severity: 4, severityConfidence: 0.5, actionable: 0.9 }),
      'prioritize'
    );
    assert.equal(
      decideReflex({ ...base, severity: 4, severityConfidence: 0.9, actionable: 0.4 }),
      'prioritize'
    );
    assert.equal(
      decideReflex({ ...base, severity: 2, severityConfidence: 0.9, actionable: 0.9 }),
      'prioritize'
    );
  });

  it('prioritizes medium reports for the moderation queue', () => {
    assert.equal(decideReflex({ ...base, severity: 2 }), 'prioritize');
    assert.equal(decideReflex({ ...base, severity: 0, actionable: 0.6 }), 'prioritize');
  });

  it('leaves harmless reports alone', () => {
    assert.equal(decideReflex({ ...base }), 'none');
    assert.equal(decideReflex({ ...base, severity: 1, actionable: 0.3 }), 'none');
    assert.equal(decideReflex(null), 'none');
  });
});
