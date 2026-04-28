import { IsEnum, IsOptional, IsString } from 'class-validator';
import { Category } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateScanDto {
  @ApiProperty({ enum: Category, description: 'Product category hint' })
  @IsEnum(Category)
  category!: Category;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  lang?: string;
}
