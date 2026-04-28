import * as Sentry from '@sentry/node';
import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import pino from 'pino';
import pinoHttp from 'pino-http';
import { randomUUID } from 'crypto';

if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV ?? 'development',
    tracesSampleRate: 0.2,
  });
}

async function bootstrap() {
  const logger = pino({ level: process.env.LOG_LEVEL ?? 'info' });

  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: false }),
  );

  // ── Multipart (file uploads) ─────────────────────────────────────
  await app.register(import('@fastify/multipart'), {
    limits: { fileSize: 10 * 1024 * 1024, files: 1 },
  });

  // ── Security headers ────────────────────────────────────────────
  await app.register(import('@fastify/helmet'), {
    contentSecurityPolicy: process.env.NODE_ENV === 'production',
  });

  // ── CORS ────────────────────────────────────────────────────────
  const allowedOrigins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  await app.register(import('@fastify/cors'), {
    origin:
      allowedOrigins.length > 0
        ? allowedOrigins
        : process.env.NODE_ENV === 'production'
          ? false
          : true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    credentials: true,
  });

  // ── Request logging with request ID ─────────────────────────────
  app.use(
    pinoHttp({
      logger,
      genReqId: () => randomUUID(),
      customLogLevel: (_req, res) => {
        if (res.statusCode >= 500) return 'error';
        if (res.statusCode >= 400) return 'warn';
        return 'info';
      },
      serializers: {
        req: (req) => ({ method: req.method, url: req.url, id: req.id }),
        res: (res) => ({ statusCode: res.statusCode }),
      },
    }),
  );

  // ── Versioning + Validation ──────────────────────────────────────
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // ── Swagger (dev/staging only) ───────────────────────────────────
  if (process.env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('Clera API')
      .setDescription('Clera ingredient analysis API')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('docs', app, document);
  }

  // ── Graceful shutdown ────────────────────────────────────────────
  app.enableShutdownHooks();

  const port = process.env.PORT ?? 8080;
  await app.listen(port, '0.0.0.0');
  logger.info(`Clera API listening on port ${port}`);
}

bootstrap();
