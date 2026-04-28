import { Module } from '@nestjs/common';
import { ScansService } from './scans.service';
import { ScansPdfService } from './scans.pdf.service';
import { ScansController } from './scans.controller';

@Module({
  controllers: [ScansController],
  providers: [ScansService, ScansPdfService],
})
export class ScansModule {}
