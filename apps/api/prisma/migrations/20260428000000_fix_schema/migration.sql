-- CreateEnum for PurchaseDecision (if not exists)
DO $$ BEGIN
  CREATE TYPE "PurchaseDecision" AS ENUM ('buying', 'not_buying', 'maybe');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- CreateTable ProductImage
CREATE TABLE IF NOT EXISTS "ProductImage" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "imageHash" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "category" "Category" NOT NULL,
    "productName" TEXT,
    "brand" TEXT,
    "country" TEXT,
    "city" TEXT,
    "scanCount" INTEGER NOT NULL DEFAULT 1,
    "firstSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ProductImage_pkey" PRIMARY KEY ("id")
);

-- CreateTable PurchaseIntent
CREATE TABLE IF NOT EXISTS "PurchaseIntent" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "scanId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "decision" "PurchaseDecision" NOT NULL,
    "reason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PurchaseIntent_pkey" PRIMARY KEY ("id")
);

-- Add productImageId to Scan
ALTER TABLE "Scan" ADD COLUMN IF NOT EXISTS "productImageId" UUID;

-- Fix Subscription: startedAt default + compound unique
ALTER TABLE "Subscription" ALTER COLUMN "startedAt" SET DEFAULT CURRENT_TIMESTAMP;

DO $$ BEGIN
  ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_userId_productId_key" UNIQUE ("userId", "productId");
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Fix Feedback: nullable scanId, non-null comment, add type
ALTER TABLE "Feedback" DROP CONSTRAINT IF EXISTS "Feedback_scanId_fkey";
ALTER TABLE "Feedback" ALTER COLUMN "scanId" DROP NOT NULL;
ALTER TABLE "Feedback" ALTER COLUMN "rating" DROP NOT NULL;
UPDATE "Feedback" SET "comment" = '' WHERE "comment" IS NULL;
ALTER TABLE "Feedback" ALTER COLUMN "comment" SET NOT NULL;
ALTER TABLE "Feedback" ADD COLUMN IF NOT EXISTS "type" TEXT;
DROP INDEX IF EXISTS "Feedback_scanId_userId_key";

-- Indexes
CREATE UNIQUE INDEX IF NOT EXISTS "ProductImage_imageHash_key" ON "ProductImage"("imageHash");
CREATE INDEX IF NOT EXISTS "ProductImage_brand_idx" ON "ProductImage"("brand");
CREATE INDEX IF NOT EXISTS "ProductImage_category_idx" ON "ProductImage"("category");
CREATE INDEX IF NOT EXISTS "ProductImage_country_city_idx" ON "ProductImage"("country", "city");
CREATE UNIQUE INDEX IF NOT EXISTS "PurchaseIntent_scanId_key" ON "PurchaseIntent"("scanId");
CREATE INDEX IF NOT EXISTS "PurchaseIntent_userId_idx" ON "PurchaseIntent"("userId");
CREATE INDEX IF NOT EXISTS "PurchaseIntent_decision_idx" ON "PurchaseIntent"("decision");
CREATE INDEX IF NOT EXISTS "PurchaseIntent_scanId_idx" ON "PurchaseIntent"("scanId");
CREATE INDEX IF NOT EXISTS "Scan_productImageId_idx" ON "Scan"("productImageId");
CREATE INDEX IF NOT EXISTS "Feedback_userId_idx" ON "Feedback"("userId");

-- Foreign keys (wrapped in DO blocks to skip if already exists)
DO $$ BEGIN
  ALTER TABLE "Scan" ADD CONSTRAINT "Scan_productImageId_fkey"
    FOREIGN KEY ("productImageId") REFERENCES "ProductImage"("id") ON DELETE SET NULL ON UPDATE CASCADE NOT VALID;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "PurchaseIntent" ADD CONSTRAINT "PurchaseIntent_scanId_fkey"
    FOREIGN KEY ("scanId") REFERENCES "Scan"("id") ON DELETE CASCADE ON UPDATE CASCADE NOT VALID;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "PurchaseIntent" ADD CONSTRAINT "PurchaseIntent_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE NOT VALID;
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "Feedback" ADD CONSTRAINT "Feedback_scanId_fkey"
    FOREIGN KEY ("scanId") REFERENCES "Scan"("id") ON DELETE SET NULL ON UPDATE CASCADE NOT VALID;
EXCEPTION WHEN duplicate_object THEN null;
END $$;
