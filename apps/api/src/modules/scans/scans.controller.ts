import {
  Controller,
  Post,
  Get,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
  DefaultValuePipe,
  BadRequestException,
  Res,
  Req,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConsumes,
  ApiTags,
  ApiQuery,
} from '@nestjs/swagger';
import { AuthGuard } from '../../common/guards/auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '@supabase/supabase-js';
import { ScansService } from './scans.service';
import { ScansPdfService } from './scans.pdf.service';
import { PurchaseIntentDto } from './dto/purchase-intent.dto';
import { FastifyRequest, FastifyReply } from 'fastify';
import { Category } from '@prisma/client';

@ApiTags('scans')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('scans')
export class ScansController {
  constructor(private scans: ScansService, private pdf: ScansPdfService) {}

  @Post()
  @ApiConsumes('multipart/form-data')
  async create(@CurrentUser() user: User, @Req() req: FastifyRequest) {
    const data = await req.file();
    if (!data) throw new BadRequestException('No file uploaded');

    const category = (data.fields['category'] as any)?.value as Category;
    if (!category) throw new BadRequestException('category field is required');

    const lang = (data.fields['lang'] as any)?.value as string | undefined;

    const imageBuffer = await data.toBuffer();
    if (imageBuffer.length > 10 * 1024 * 1024) {
      throw new BadRequestException('Image must be under 10 MB');
    }

    return this.scans.create(
      user.id,
      { category, lang },
      imageBuffer,
      data.mimetype,
    );
  }

  @Get()
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  findAll(
    @CurrentUser() user: User,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.scans.findAll(user.id, page, Math.min(limit, 100));
  }

  @Get(':id')
  findOne(@CurrentUser() user: User, @Param('id') id: string) {
    return this.scans.findById(id, user.id);
  }

  @Get(':id/pdf')
  async exportPdf(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Res() res: FastifyReply,
  ) {
    const html = await this.pdf.generateHtml(id, user.id);
    res
      .header('Content-Type', 'text/html; charset=utf-8')
      .header('Content-Disposition', `attachment; filename="clera-scan-${id}.html"`)
      .send(html);
  }

  @Put(':id/intent')
  savePurchaseIntent(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() dto: PurchaseIntentDto,
  ) {
    return this.scans.savePurchaseIntent(user.id, id, dto);
  }
}
