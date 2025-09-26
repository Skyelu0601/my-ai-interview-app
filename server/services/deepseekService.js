import axios from 'axios';

const DEEPSEEK_ENDPOINT = 'https://api.deepseek.com/v1/chat/completions';

/**
 * Send a prompt to DeepSeek and return the model content string.
 * @param {string} prompt - The user/system prompt to send to the model.
 * @param {object} [options]
 * @param {string} [options.model='deepseek-chat'] - Model name.
 * @param {number} [options.temperature=0.7] - Sampling temperature.
 * @param {number} [options.maxTokens=2000] - Max tokens for completion.
 * @returns {Promise<string>} content returned by the model
 */
export async function sendPromptToDeepSeek(prompt, options = {}) {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) {
    throw new Error('DEEPSEEK_API_KEY is not set');
  }

  const {
    model = 'deepseek-chat',
    temperature = 0.75,
    maxTokens = 2200,
    debug = false,
    systemPrompt,
    retries = 2,
    retryDelayMs = 600,
  } = options;

  const messages = systemPrompt
    ? [ { role: 'system', content: systemPrompt }, { role: 'user', content: prompt } ]
    : [ { role: 'user', content: prompt } ];

  const payload = {
    model,
    messages,
    temperature,
    max_tokens: maxTokens,
  };

  if (debug) {
    console.log('--- DeepSeek Super Prompt ---');
    console.log(prompt);
    console.log('--- DeepSeek Request Payload ---');
    try {
      console.log(JSON.stringify(payload, null, 2));
    } catch (_) {
      console.log(payload);
    }
  }

  let lastErr;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const resp = await axios.post(
        DEEPSEEK_ENDPOINT,
        payload,
        {
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${apiKey}`,
          },
          timeout: 45000,
          validateStatus: () => true,
        },
      );

      // Non-2xx handling with meaningful error
      if (resp.status < 200 || resp.status >= 300) {
        const snippet = typeof resp.data === 'string' ? resp.data.slice(0, 500) : JSON.stringify(resp.data).slice(0, 500);
        const errMsg = `DeepSeek HTTP ${resp.status}: ${snippet}`;
        throw new Error(errMsg);
      }

      if (debug) {
        console.log('--- DeepSeek Raw Response ---');
        try {
          console.log(JSON.stringify(resp.data, null, 2));
        } catch (_) {
          console.log(resp.data);
        }
      }

      const content = resp?.data?.choices?.[0]?.message?.content;
      if (typeof content !== 'string' || content.length === 0) {
        throw new Error('Empty content from DeepSeek response');
      }
      return content;
    } catch (err) {
      lastErr = err;
      if (attempt < retries) {
        if (debug) {
          console.log(`DeepSeek attempt ${attempt + 1} failed: ${String(err.message || err)}. Retrying in ${retryDelayMs}ms...`);
        }
        await new Promise((r) => setTimeout(r, retryDelayMs));
        continue;
      }
    }
  }

  const status = lastErr?.response?.status;
  const body = lastErr?.response?.data;
  const msg = `DeepSeek request failed after ${retries + 1} attempt(s)${status ? ` (status ${status})` : ''}`;
  const details = body ? `: ${typeof body === 'string' ? body.slice(0, 500) : JSON.stringify(body).slice(0, 500)}` : '';
  throw new Error(msg + details);
}

/**
 * Send a prompt to DeepSeek with streaming response.
 * @param {string} prompt - The user/system prompt to send to the model.
 * @param {object} [options]
 * @param {string} [options.model='deepseek-chat'] - Model name.
 * @param {number} [options.temperature=0.7] - Sampling temperature.
 * @param {number} [options.maxTokens=2000] - Max tokens for completion.
 * @param {function} [options.onChunk] - Callback for each chunk received.
 * @returns {Promise<string>} complete content returned by the model
 */
export async function sendPromptToDeepSeekStream(prompt, options = {}) {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) {
    throw new Error('DEEPSEEK_API_KEY is not set');
  }

  const {
    model = 'deepseek-chat',
    temperature = 0.75,
    maxTokens = 2000,
    debug = false,
    systemPrompt,
    onChunk,
    retries = 2,
    retryDelayMs = 600,
  } = options;

  const messages = systemPrompt
    ? [ { role: 'system', content: systemPrompt }, { role: 'user', content: prompt } ]
    : [ { role: 'user', content: prompt } ];

  const payload = {
    model,
    messages,
    temperature,
    max_tokens: maxTokens,
    stream: true,
  };

  if (debug) {
    console.log('--- DeepSeek Streaming Request ---');
    console.log(JSON.stringify(payload, null, 2));
  }

  let lastErr;
  let fullContent = '';

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const response = await axios.post(
        DEEPSEEK_ENDPOINT,
        payload,
        {
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${apiKey}`,
          },
          timeout: 45000,
          validateStatus: () => true,
          responseType: 'stream',
        },
      );

      if (response.status !== 200) {
        throw new Error(`DeepSeek HTTP ${response.status}`);
      }

      return new Promise((resolve, reject) => {
        response.data.on('data', (chunk) => {
          const lines = chunk.toString().split('\n');
          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const data = line.slice(6);
              if (data === '[DONE]') {
                resolve(fullContent);
                return;
              }
              try {
                const parsed = JSON.parse(data);
                const content = parsed.choices?.[0]?.delta?.content;
                if (content) {
                  fullContent += content;
                  if (onChunk) {
                    onChunk(content);
                  }
                }
              } catch (e) {
                // Ignore parsing errors for incomplete chunks
              }
            }
          }
        });

        response.data.on('error', (err) => {
          reject(err);
        });

        response.data.on('end', () => {
          resolve(fullContent);
        });
      });
    } catch (err) {
      lastErr = err;
      if (attempt < retries) {
        if (debug) {
          console.log(`DeepSeek streaming attempt ${attempt + 1} failed: ${String(err.message || err)}. Retrying in ${retryDelayMs}ms...`);
        }
        await new Promise((r) => setTimeout(r, retryDelayMs));
        continue;
      }
    }
  }

  throw new Error(`DeepSeek streaming request failed after ${retries + 1} attempt(s): ${lastErr?.message || lastErr}`);
}

export default { sendPromptToDeepSeek, sendPromptToDeepSeekStream };

