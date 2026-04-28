import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../infra/database/prisma.service';
import { UpsertUserDto } from './dto/upsert-user.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async upsert(supabaseUid: string, dto: UpsertUserDto) {
    return this.prisma.user.upsert({
      where: { id: supabaseUid },
      create: {
        id: supabaseUid,
        ...dto,
        locale: dto.locale ?? 'en-IN',
      },
      update: {
        name: dto.name,
        age: dto.age,
        gender: dto.gender,
        locale: dto.locale,
        country: dto.country,
        city: dto.city,
      },
    });
  }

  async findById(id: string) {
    const user = await this.prisma.user.findFirst({
      where: { id, deletedAt: null },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async softDelete(id: string) {
    await this.prisma.user.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}
