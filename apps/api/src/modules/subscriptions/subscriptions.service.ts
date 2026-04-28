import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../../infra/database/prisma.service';
import { VerifyReceiptDto, SubscriptionPlatform } from './dto/verify-receipt.dto';
import { Tier } from '@prisma/client';

const PRODUCT_TIER: Record<string, Tier> = {
  clera_pro_annual:  'pro',
  clera_pro_monthly: 'pro',
  clera_family_annual: 'family',
};

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);

  constructor(private prisma: PrismaService) {}

  async verify(userId: string, dto: VerifyReceiptDto) {
    const tier = PRODUCT_TIER[dto.productId];
    if (!tier) throw new BadRequestException(`Unknown product: ${dto.productId}`);

    // --- Platform verification ---
    // In production: call Apple/Google receipt validation APIs here.
    // For now we trust the client and record the receipt for manual auditing.
    // TODO: integrate with RevenueCat or direct Apple/Google server APIs.
    this.logger.log(`Receipt received for ${userId} — platform:${dto.platform} product:${dto.productId}`);

    const renewsAt = new Date();
    if (dto.productId.includes('annual') || dto.productId.includes('family')) {
      renewsAt.setFullYear(renewsAt.getFullYear() + 1);
    } else {
      renewsAt.setMonth(renewsAt.getMonth() + 1);
    }

    await this.prisma.$transaction([
      // Upsert subscription record (compound unique on userId+productId)
      this.prisma.subscription.upsert({
        where: { userId_productId: { userId, productId: dto.productId } },
        create: {
          userId,
          platform: dto.platform,
          productId: dto.productId,
          status: 'active',
          receipt: dto.receipt,
          renewsAt,
        },
        update: {
          platform: dto.platform,
          status: 'active',
          receipt: dto.receipt,
          renewsAt,
        },
      }),
      // Upgrade user tier
      this.prisma.user.update({
        where: { id: userId },
        data: { tier },
      }),
    ]);

    return { tier, renewsAt, status: 'active' };
  }

  async getStatus(userId: string) {
    const sub = await this.prisma.subscription.findFirst({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
    });
    const user = await this.prisma.user.findFirstOrThrow({
      where: { id: userId },
      select: { tier: true },
    });
    return { tier: user.tier, subscription: sub ?? null };
  }

  async cancel(userId: string) {
    await this.prisma.$transaction([
      this.prisma.subscription.updateMany({
        where: { userId, status: 'active' },
        data: { status: 'cancelled' },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: { tier: 'free' },
      }),
    ]);
    return { tier: 'free', status: 'cancelled' };
  }
}
