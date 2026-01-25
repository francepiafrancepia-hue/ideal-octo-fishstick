import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { buildPromptForSkill, listSkillNames, skillCatalog } from './skillLibrary.js';
import { generateCompletion, getDefaults, listModels } from './ollamaClient.js';

const server = new McpServer(
  {
    name: 'ollama-agent-skills',
    version: '1.0.0'
  },
  {
    capabilities: {
      tools: {},
      logging: {}
    }
  }
);

server.registerTool(
  'ollama_generate',
  {
    title: 'Ollama generate',
    description: 'Generate a response from Ollama for a prompt.',
    inputSchema: {
      prompt: z.string().describe('Prompt to send to Ollama'),
      model: z.string().optional().describe('Optional model name'),
      system: z.string().optional().describe('Optional system prompt'),
      temperature: z.number().min(0).max(2).optional().describe('Sampling temperature override')
    }
  },
  async ({ prompt, model, system, temperature }) => {
    const defaults = getDefaults();
    const response = await generateCompletion({
      prompt,
      model: model ?? defaults.model,
      system,
      options: temperature !== undefined ? { temperature } : undefined
    });

    return {
      content: [
        {
          type: 'text',
          text: response.response
        }
      ]
    };
  }
);

server.registerTool(
  'ollama_list_models',
  {
    title: 'Ollama list models',
    description: 'List available Ollama models.',
    inputSchema: {}
  },
  async () => {
    const models = await listModels();
    return {
      content: [
        {
          type: 'text',
          text: models.length ? models.join('\n') : 'No models found.'
        }
      ]
    };
  }
);

server.registerTool(
  'agent_skill',
  {
    title: 'Agent skill',
    description: 'Run a curated agent skill using Ollama.',
    inputSchema: {
      skill: z.enum(listSkillNames()).describe('Skill to run'),
      input: z.string().describe('Input for the skill'),
      model: z.string().optional().describe('Optional model name override')
    }
  },
  async ({ skill, input, model }) => {
    const prompt = buildPromptForSkill(skill, input);
    const response = await generateCompletion({
      prompt,
      model
    });

    return {
      content: [
        {
          type: 'text',
          text: response.response
        }
      ]
    };
  }
);

server.registerTool(
  'list_agent_skills',
  {
    title: 'List agent skills',
    description: 'List the available agent skills and their descriptions.',
    inputSchema: {}
  },
  async () => {
    const lines = skillCatalog.map(skill => `${skill.name}: ${skill.description}`);
    return {
      content: [
        {
          type: 'text',
          text: lines.join('\n')
        }
      ]
    };
  }
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.log('Ollama MCP server running with agent skills.');
}

main().catch(error => {
  console.error('Server error:', error);
  process.exit(1);
});
