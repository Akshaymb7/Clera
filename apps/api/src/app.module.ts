import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { HealthModule } from './modules/health/health.module';
import { DatabaseModule } from './infra/database/database.module';
import { SupabaseModule } from './infra/supabase/supabase.module';
import { UsersModule } from './modules/users/users.module';
import { ScansModule } from './modules/scans/scans.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { FeedbackModule } from './modules/feedback/feedback.module';
import { QuotaModule } from './common/quota/quota.module';
import { S3Module } from './infra/s3/s3.module';
import { AnthropicModule } from './infra/anthropic/anthropic.module';
import { AuthGuard } from './common/guards/auth.guard';
import { ThrottleByUserGuard } from './common/guards/throttle-by-user.guard';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 60 }]),
    DatabaseModule,
    SupabaseModule,
    HealthModule,
    S3Module,
    AnthropicModule,
    UsersModule,
    ScansModule,
    SubscriptionsModule,
    FeedbackModule,
    QuotaModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_GUARD, useClass: ThrottleByUserGuard },
    { provide: APP_FILTER, useClass: GlobalExceptionFilter },
  ],
})
export class AppModule {}
