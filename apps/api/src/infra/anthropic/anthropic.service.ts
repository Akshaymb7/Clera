import { Injectable, BadGatewayException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Anthropic from '@anthropic-ai/sdk';
import { Category } from '@prisma/client';

export interface LabelAnalysisResult {
  productName: string | null;
  brand: string | null;
  category: Category;
  lang: string;
  score: number;
  band: 'excellent' | 'good' | 'caution' | 'poor' | 'avoid';
  ingredients: {
    name: string;
    normalizedName: string;
    riskLevel: 'safe' | 'low' | 'moderate' | 'high' | 'critical';
    reason: string;
    regulatoryFlags: string[];
  }[];
  personalizedFlags: string[];
  summary: string;
  // usage metadata
  model: string;
  inputTokens: number;
  outputTokens: number;
  latencyMs: number;
}

interface UserProfile {
  age: number;
  gender: string;
  locale: string;
  profileJson?: Record<string, unknown> | null;
}

@Injectable()
export class AnthropicService {
  private readonly client: Anthropic;
  private readonly modelDefault: string;
  private readonly modelFast: string;
  private readonly modelEscalate: string;
  private readonly maxTokens: number;

  constructor(private config: ConfigService) {
    this.client = new Anthropic({
      apiKey: config.getOrThrow('ANTHROPIC_API_KEY'),
    });
    this.modelDefault = config.get('ANTHROPIC_MODEL_DEFAULT', 'claude-sonnet-4-6');
    this.modelFast = config.get('ANTHROPIC_MODEL_FAST', 'claude-haiku-4-5-20251001');
    this.modelEscalate = config.get('ANTHROPIC_MODEL_ESCALATE', 'claude-opus-4-6');
    this.maxTokens = config.get<number>('ANTHROPIC_MAX_OUTPUT_TOKENS', 1500);
  }

  async analyzeLabel(
    imageBuffer: Buffer,
    mediaType: 'image/jpeg' | 'image/png' | 'image/webp',
    category: Category,
    lang: string,
    user: UserProfile,
    escalate = false,
  ): Promise<LabelAnalysisResult> {
    const model = escalate ? this.modelEscalate : this.modelDefault;
    const profile = (user.profileJson ?? {}) as Record<string, unknown>;

    const userMessage = [
      `Category hint: ${category}`,
      `User profile:`,
      `- age: ${user.age}`,
      `- gender: ${user.gender}`,
      `- allergies: ${(profile.allergies as string) ?? 'none'}`,
      `- conditions: ${(profile.conditions as string) ?? 'none'}`,
      `- pregnancy: ${(profile.pregnancy as string) ?? 'no'}`,
      `Locale: ${user.locale}`,
      ``,
      `Return only the JSON object.`,
    ].join('\n');

    const start = Date.now();
    let response: Anthropic.Message;

    try {
      response = await this.client.messages.create({
        model,
        max_tokens: this.maxTokens,
        system: SYSTEM_PROMPT,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: {
                  type: 'base64',
                  media_type: mediaType,
                  data: imageBuffer.toString('base64'),
                },
              },
              { type: 'text', text: userMessage },
            ],
          },
        ],
      });
    } catch (err) {
      throw new BadGatewayException(`Anthropic error: ${(err as Error).message}`);
    }

    const latencyMs = Date.now() - start;
    const raw = (response.content[0] as Anthropic.TextBlock).text.trim();

    let parsed: Omit<LabelAnalysisResult, 'model' | 'inputTokens' | 'outputTokens' | 'latencyMs'>;
    try {
      // Strip markdown code fences if model wraps in ```json
      const json = raw.replace(/^```json\s*/i, '').replace(/```$/i, '').trim();
      parsed = JSON.parse(json);
    } catch {
      // Auto-escalate on parse failure if not already escalated
      if (!escalate) {
        return this.analyzeLabel(imageBuffer, mediaType, category, lang, user, true);
      }
      throw new BadGatewayException('Failed to parse Claude response as JSON');
    }

    return {
      ...parsed,
      model,
      inputTokens: response.usage.input_tokens,
      outputTokens: response.usage.output_tokens,
      latencyMs,
    };
  }
}

const SYSTEM_PROMPT = `You are Clera's Label Analyst. Given a photo of a product ingredient label,
you identify the product, list all ingredients in label order, and assess safety.

Rules:
- Only use what is visible on the label or common knowledge about the named ingredient.
- Do NOT invent regulatory rulings. If unsure, mark risk_level "low" and say so in the reason.
- Personalize using the user's profile when provided (allergies, conditions, pregnancy).
- Plain-language explanations, 1–2 short sentences each. No jargon unless you define it.
- For medicines, add the fixed disclaimer "Not medical advice — consult a professional."
- Always return valid JSON that matches the schema exactly. No prose outside JSON.

Scoring rubric (0–100, higher = safer):
- 85–100 excellent: no meaningful concerns
- 70–84 good: minor concerns, common additives
- 40–69 caution: multiple questionable ingredients or one moderate allergen match
- 20–39 poor: multiple moderate or one high-risk ingredient
- 0–19 avoid: banned, carcinogenic, or major regulatory warnings present

JSON schema:
{
  "productName": string | null,
  "brand": string | null,
  "category": "food" | "cosmetic" | "medicine" | "household",
  "lang": string,
  "score": integer (0-100),
  "band": "excellent" | "good" | "caution" | "poor" | "avoid",
  "ingredients": [
    {
      "name": string,
      "normalizedName": string,
      "riskLevel": "safe" | "low" | "moderate" | "high" | "critical",
      "reason": string,
      "regulatoryFlags": string[]
    }
  ],
  "personalizedFlags": string[],
  "summary": string
}`;
