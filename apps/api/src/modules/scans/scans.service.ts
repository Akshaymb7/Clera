import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/database/prisma.service';
import { S3Service } from '../../infra/s3/s3.service';
import { AnthropicService } from '../../infra/anthropic/anthropic.service';
import { QuotaService } from '../../common/quota/quota.service';
import { CreateScanDto } from './dto/create-scan.dto';
import { PurchaseIntentDto } from './dto/purchase-intent.dto';
import { Decimal } from '@prisma/client/runtime/library';

const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp'] as const;
type AllowedMime = (typeof ALLOWED_MIME)[number];

// Cost per 1M tokens (claude-sonnet-4-6 pricing)
const COST_PER_INPUT_TOKEN = 3.0 / 1_000_000;
const COST_PER_OUTPUT_TOKEN = 15.0 / 1_000_000;

@Injectable()
export class ScansService {
  constructor(
    private prisma: PrismaService,
    private s3: S3Service,
    private anthropic: AnthropicService,
    private quota: QuotaService,
  ) {}

  async create(
    userId: string,
    dto: CreateScanDto,
    imageBuffer: Buffer,
    mimeType: string,
  ) {
    if (!ALLOWED_MIME.includes(mimeType as AllowedMime)) {
      throw new BadRequestException(
        `Unsupported image type. Allowed: ${ALLOWED_MIME.join(', ')}`,
      );
    }

    // 1. Enforce quota
    await this.quota.assertCanScan(userId);

    // 2. Hash image — skip re-analysis if same image scanned before by this user
    const imageHash = this.s3.sha256(imageBuffer);
    const existing = await this.prisma.scan.findFirst({
      where: { userId, imageHash },
      include: { ingredients: true },
    });
    if (existing) return existing;

    // 3. Upload to S3
    const ext = mimeType.split('/')[1];
    const s3Key = `scans/${userId}/${imageHash}.${ext}`;
    await this.s3.upload(s3Key, imageBuffer, mimeType);

    // 4. Fetch user profile for personalization
    const user = await this.prisma.user.findFirstOrThrow({
      where: { id: userId, deletedAt: null },
    });

    // 5. Call Claude
    const result = await this.anthropic.analyzeLabel(
      imageBuffer,
      mimeType as AllowedMime,
      dto.category,
      dto.lang ?? user.locale ?? 'en',
      {
        age: user.age,
        gender: user.gender,
        locale: user.locale,
        profileJson: user.profileJson as Record<string, unknown> | null,
      },
    );

    // 6. Calculate cost
    const costUsd =
      result.inputTokens * COST_PER_INPUT_TOKEN +
      result.outputTokens * COST_PER_OUTPUT_TOKEN;

    // 7. Persist scan + ingredients in a transaction
    const scan = await this.prisma.$transaction(async (tx) => {
      // Upsert ProductImage (deduplicated product label library)
      const productImage = await tx.productImage.upsert({
        where: { imageHash },
        create: {
          imageHash,
          storageKey: s3Key,
          mimeType,
          category: result.category,
          productName: result.productName,
          brand: result.brand,
          country: user.country,
          city: user.city,
        },
        update: {
          scanCount: { increment: 1 },
          lastSeenAt: new Date(),
          productName: result.productName ?? undefined,
          brand: result.brand ?? undefined,
        },
      });

      const saved = await tx.scan.create({
        data: {
          userId,
          category: result.category,
          productName: result.productName,
          brand: result.brand,
          imageS3Key: s3Key,
          imageHash,
          score: result.score,
          band: result.band,
          lang: result.lang,
          model: result.model,
          inputTokens: result.inputTokens,
          outputTokens: result.outputTokens,
          latencyMs: result.latencyMs,
          costUsd: new Decimal(costUsd),
          rawResponse: result as object,
          productImageId: productImage.id,
        },
      });

      await tx.scanIngredient.createMany({
        data: result.ingredients.map((ing, i) => ({
          scanId: saved.id,
          name: ing.name,
          normalizedName: ing.normalizedName,
          riskLevel: ing.riskLevel,
          reason: ing.reason,
          regulatoryFlags: ing.regulatoryFlags,
          position: i,
        })),
      });

      // Upsert daily usage stats
      const day = new Date();
      day.setHours(0, 0, 0, 0);
      await tx.apiUsageDaily.upsert({
        where: { day_userId_model: { day, userId, model: result.model } },
        create: {
          day,
          userId,
          model: result.model,
          inputTokens: BigInt(result.inputTokens),
          outputTokens: BigInt(result.outputTokens),
          costUsd: new Decimal(costUsd),
        },
        update: {
          inputTokens: { increment: BigInt(result.inputTokens) },
          outputTokens: { increment: BigInt(result.outputTokens) },
          costUsd: { increment: new Decimal(costUsd) },
        },
      });

      return saved;
    });

    return this.findById(scan.id, userId);
  }

  async findAll(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [items, total] = await Promise.all([
      this.prisma.scan.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: { ingredients: { orderBy: { position: 'asc' } } },
      }),
      this.prisma.scan.count({ where: { userId } }),
    ]);
    return { items, total, page, limit };
  }

  async findById(id: string, userId: string) {
    const scan = await this.prisma.scan.findFirst({
      where: { id, userId },
      include: {
        ingredients: { orderBy: { position: 'asc' } },
        purchaseIntent: true,
      },
    });
    if (!scan) throw new NotFoundException('Scan not found');
    return scan;
  }

  async savePurchaseIntent(userId: string, scanId: string, dto: PurchaseIntentDto) {
    // Verify scan belongs to user
    const scan = await this.prisma.scan.findFirst({ where: { id: scanId, userId } });
    if (!scan) throw new NotFoundException('Scan not found');

    return this.prisma.purchaseIntent.upsert({
      where: { scanId },
      create: { scanId, userId, decision: dto.decision, reason: dto.reason },
      update: { decision: dto.decision, reason: dto.reason },
    });
  }
}
