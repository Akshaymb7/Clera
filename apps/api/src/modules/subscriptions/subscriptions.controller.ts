import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../../common/guards/auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '@supabase/supabase-js';
import { SubscriptionsService } from './subscriptions.service';
import { VerifyReceiptDto } from './dto/verify-receipt.dto';

@ApiTags('subscriptions')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private subs: SubscriptionsService) {}

  @Post('verify')
  verify(@CurrentUser() user: User, @Body() dto: VerifyReceiptDto) {
    return this.subs.verify(user.id, dto);
  }

  @Get('status')
  getStatus(@CurrentUser() user: User) {
    return this.subs.getStatus(user.id);
  }

  @Delete('cancel')
  @HttpCode(HttpStatus.OK)
  cancel(@CurrentUser() user: User) {
    return this.subs.cancel(user.id);
  }
}
