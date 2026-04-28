export type Tier = 'free' | 'pro' | 'family';
export type Gender = 'male' | 'female' | 'non_binary' | 'prefer_not_to_say';
export type Category = 'food' | 'cosmetic' | 'medicine' | 'household';
export type Band = 'excellent' | 'good' | 'caution' | 'poor' | 'avoid';
export type RiskLevel = 'safe' | 'low' | 'moderate' | 'high' | 'critical';

export interface ScanIngredient {
  name: string;
  normalizedName: string;
  riskLevel: RiskLevel;
  reason: string;
  regulatoryFlags: string[];
}

export interface ScanResult {
  id: string;
  category: Category;
  productName: string | null;
  brand: string | null;
  lang: string;
  score: number;
  band: Band;
  ingredients: ScanIngredient[];
  summary: string;
  personalizedFlags: string[];
  createdAt: string;
}

export interface UserProfile {
  id: string;
  email: string;
  name: string;
  age: number;
  gender: Gender;
  locale: string;
  country?: string;
  city?: string;
  tier: Tier;
  profileJson?: UserProfileJson;
  createdAt: string;
}

export interface UserProfileJson {
  allergies?: string[];
  conditions?: string[];
  pregnancy?: boolean;
}

export interface QuotaStatus {
  used: number;
  limit: number;
  resetAt: string;
}

export interface ProblemDetail {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance?: string;
}
