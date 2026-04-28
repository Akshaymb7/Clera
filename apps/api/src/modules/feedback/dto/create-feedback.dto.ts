import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateFeedbackDto {
  @IsOptional()
  @IsString()
  scanId?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  rating?: number;

  @IsString()
  comment!: string;

  @IsOptional()
  @IsString()
  type?: string; // 'bug' | 'feature' | 'general'
}
