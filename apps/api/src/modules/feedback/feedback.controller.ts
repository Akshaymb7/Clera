import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../../common/guards/auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '@supabase/supabase-js';
import { PrismaService } from '../../infra/database/prisma.service';
import { CreateFeedbackDto } from './dto/create-feedback.dto';

@ApiTags('feedback')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('feedback')
export class FeedbackController {
  constructor(private prisma: PrismaService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@CurrentUser() user: User, @Body() dto: CreateFeedbackDto) {
    return this.prisma.feedback.create({
      data: {
        userId: user.id,
        scanId: dto.scanId ?? null,
        type: dto.type ?? null,
        rating: dto.rating ?? null,
        comment: dto.comment,
      },
    });
  }
}
