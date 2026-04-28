import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../../common/guards/auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '@supabase/supabase-js';
import { UsersService } from './users.service';
import { UpsertUserDto } from './dto/upsert-user.dto';
import { QuotaService } from '../../common/quota/quota.service';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('users')
export class UsersController {
  constructor(
    private users: UsersService,
    private quota: QuotaService,
  ) {}

  @Put('me')
  upsertMe(@CurrentUser() user: User, @Body() dto: UpsertUserDto) {
    return this.users.upsert(user.id, dto);
  }

  @Get('me')
  getMe(@CurrentUser() user: User) {
    return this.users.findById(user.id);
  }

  @Get('me/quota')
  getQuota(@CurrentUser() user: User) {
    return this.quota.getStatus(user.id);
  }

  @Delete('me')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteMe(@CurrentUser() user: User) {
    await this.users.softDelete(user.id);
  }
}
