import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { PurchaseDecision } from '@prisma/client';

export class PurchaseIntentDto {
  @IsEnum(PurchaseDecision)
  decision!: PurchaseDecision;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}
