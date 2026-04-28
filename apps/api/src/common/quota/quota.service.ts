import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../infra/database/prisma.service';
import { Tier } from '@prisma/client';

const QUOTA: Record<Tier, { daily: number; monthly: number }> = {
  free:   { daily: 3,  monthly: 20  },
  pro:    { daily: 50, monthly: 300 },
  family: { daily: 50, monthly: 300 },
};

@Injectable()
export class QuotaService {
  constructor(private prisma: PrismaService) {}

  async assertCanScan(userId: string): Promise<void> {
    const user = await this.prisma.user.findFirstOrThrow({
      where: { id: userId, deletedAt: null },
      select: { tier: true },
    });

    const limits = QUOTA[user.tier];
    const now = new Date();

    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [daily, monthly] = await Promise.all([
      this.prisma.scan.count({ where: { userId, createdAt: { gte: startOfDay } } }),
      this.prisma.scan.count({ where: { userId, createdAt: { gte: startOfMonth } } }),
    ]);

    if (daily >= limits.daily) {
      throw new ForbiddenException(
        `Daily scan limit of ${limits.daily} reached for ${user.tier} tier. Resets at midnight.`,
      );
    }

    if (monthly >= limits.monthly) {
      throw new ForbiddenException(
        `Monthly scan limit of ${limits.monthly} reached for ${user.tier} tier. Resets on the 1st.`,
      );
    }
  }

  async getStatus(userId: string) {
    const user = await this.prisma.user.findFirstOrThrow({
      where: { id: userId, deletedAt: null },
      select: { tier: true },
    });

    const limits = QUOTA[user.tier];
    const now = new Date();

    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [daily, monthly] = await Promise.all([
      this.prisma.scan.count({ where: { userId, createdAt: { gte: startOfDay } } }),
      this.prisma.scan.count({ where: { userId, createdAt: { gte: startOfMonth } } }),
    ]);

    return {
      tier: user.tier,
      daily:   { used: daily,   limit: limits.daily,   remaining: limits.daily   - daily   },
      monthly: { used: monthly, limit: limits.monthly, remaining: limits.monthly - monthly },
    };
  }
}
