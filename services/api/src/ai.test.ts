import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  coachBio,
  icebreakers,
  matchNote,
  scenarioIcebreakers,
  scenarioMatchNote,
  scenarioSmartReplies,
  smartReplies,
  summarizeChat
} from './services/ai.js';

/**
 * Model cagrisi yapilmaz. AI kapaliyken (env yok) butun yardimcilar guvenli
 * sekilde null doner; gomulu senaryo kutuphanesi ise modele ihtiyac duymadan
 * calisir ve ayrica test edilir.
 */
describe('ai: kapaliyken guvenli davranis', () => {
  it('returns null for every helper when the gateway is not configured', async () => {
    assert.equal(await smartReplies(['merhaba']), null);
    assert.equal(await icebreakers({ displayName: 'Zeynep', interests: ['muzik'] }), null);
    assert.equal(await coachBio('kisa bio'), null);
    assert.equal(await summarizeChat(['a', 'b', 'c', 'd']), null);
    assert.equal(await matchNote(['muzik'], 2), null);
  });

  it('never throws on empty input', async () => {
    assert.equal(await smartReplies([]), null);
    assert.equal(await summarizeChat([]), null);
    assert.equal(await icebreakers({ displayName: '', interests: [] }), null);
  });

  it('resolves to null (never rejects) for concurrent calls', async () => {
    const results = await Promise.all([
      smartReplies(['selam']),
      icebreakers({ displayName: 'Ali', interests: ['seyahat'] }),
      matchNote(['kultur'], 1),
      summarizeChat(['bir', 'iki', 'ucuncu', 'dorduncu'])
    ]);
    assert.deepEqual(results, [null, null, null, null]);
  });
});

describe('ai: gomulu senaryo kutuphanesi (model gerektirmez)', () => {
  it('matches the last message against known scenarios', () => {
    const thanks = scenarioSmartReplies(['Görüşürüz', 'Sağ ol']);
    assert.ok(thanks);
    assert.equal(thanks.length, 3);
    const greeting = scenarioSmartReplies(['merhaba']);
    assert.ok(greeting);
    assert.notDeepEqual(thanks, greeting);
  });

  it('uses the newest message only', () => {
    assert.deepEqual(scenarioSmartReplies(['sağol', 'neredesin']), scenarioSmartReplies(['neredesin']));
  });

  it('returns null when no scenario matches', () => {
    assert.equal(scenarioSmartReplies(['mmmm']), null);
    assert.equal(scenarioSmartReplies([]), null);
  });

  it('prefers interests over city for icebreakers', () => {
    const openers = scenarioIcebreakers({ displayName: 'Zeynep', city: 'İzmir', interests: ['muzik', 'yürüyüş'] });
    assert.ok(openers);
    assert.equal(openers.length, 3);
    assert.ok(openers.some((line) => line.includes('Zeynep')));
    assert.ok(openers.some((line) => line.toLowerCase().includes('muzik')));
  });

  it('falls back to city then generic openers', () => {
    const byCity = scenarioIcebreakers({ displayName: 'Ali', city: 'Ankara', interests: [] });
    assert.ok(byCity);
    assert.ok(byCity.some((line) => line.includes('Ankara')));
    const generic = scenarioIcebreakers({ displayName: 'Ali', interests: [] });
    assert.ok(generic);
    assert.equal(generic.length, 3);
  });

  it('returns null without a display name', () => {
    assert.equal(scenarioIcebreakers({ displayName: '', interests: ['muzik'] }), null);
  });

  it('builds a match note from shared interests and events', () => {
    const both = scenarioMatchNote(['muzik', 'kultur'], 3);
    assert.ok(both);
    assert.ok(both.includes('muzik'));
    assert.ok(both.includes('3'));
    const onlyEvents = scenarioMatchNote([], 2);
    assert.ok(onlyEvents);
    assert.ok(onlyEvents.includes('2'));
    const single = scenarioMatchNote(['muzik'], 0);
    assert.ok(single);
    assert.ok(single.includes('muzik'));
    const none = scenarioMatchNote([], 0);
    assert.ok(none);
  });
});
