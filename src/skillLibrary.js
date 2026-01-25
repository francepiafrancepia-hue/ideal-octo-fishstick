const sanitizeText = value => value.replace(/\s+/g, ' ').trim();

export const skillCatalog = [
  {
    name: 'summarize',
    title: 'Summarize text',
    description: 'Summarize input text using Ollama.'
  },
  {
    name: 'outline',
    title: 'Create outline',
    description: 'Generate a concise outline for a topic.'
  },
  {
    name: 'brainstorm',
    title: 'Brainstorm ideas',
    description: 'Generate creative ideas for a topic.'
  }
];

export function buildPromptForSkill(skill, input) {
  const normalizedInput = sanitizeText(input);

  switch (skill) {
    case 'summarize':
      return `Summarize the following text in a few sentences:\n\n${normalizedInput}`;
    case 'outline':
      return `Create a short, organized outline for the following topic:\n\n${normalizedInput}`;
    case 'brainstorm':
      return `Brainstorm 5 concise ideas for the following topic:\n\n${normalizedInput}`;
    default:
      return `Respond helpfully to the following input:\n\n${normalizedInput}`;
  }
}

export function listSkillNames() {
  return skillCatalog.map(skill => skill.name);
}
