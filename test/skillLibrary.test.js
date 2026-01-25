import test from 'node:test';
import assert from 'node:assert/strict';
import { buildPromptForSkill, listSkillNames, skillCatalog } from '../src/skillLibrary.js';

test('buildPromptForSkill builds summarize prompts', () => {
  const prompt = buildPromptForSkill('summarize', '  Hello   world ');
  assert.match(prompt, /Summarize/);
  assert.match(prompt, /Hello world/);
});

test('listSkillNames matches catalog entries', () => {
  const names = listSkillNames();
  assert.deepEqual(names, skillCatalog.map(skill => skill.name));
});

