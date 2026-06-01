-- CreateEnum
CREATE TYPE "UserType" AS ENUM ('consumer', 'trader');

-- CreateEnum
CREATE TYPE "DealTier" AS ENUM ('basic', 'standard', 'premium');

-- CreateEnum
CREATE TYPE "DealStatus" AS ENUM ('active', 'expired', 'paused');

-- CreateEnum
CREATE TYPE "ClaimStatus" AS ENUM ('claimed', 'redeemed', 'expired');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('pending', 'completed', 'failed', 'refunded');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "type" "UserType" NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'ar',
    "fcm_token" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trader_profiles" (
    "user_id" TEXT NOT NULL,
    "business_name" TEXT NOT NULL,
    "category_id" INTEGER NOT NULL,
    "address" TEXT,
    "lat" DOUBLE PRECISION,
    "lng" DOUBLE PRECISION,
    "logo_url" TEXT,
    "rating_avg" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "rating_count" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "trader_profiles_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name_en" TEXT NOT NULL,
    "name_ar" TEXT NOT NULL,
    "icon" TEXT NOT NULL,
    "group_en" TEXT NOT NULL,
    "group_ar" TEXT NOT NULL,
    "is_gulf_exclusive" BOOLEAN NOT NULL DEFAULT false,
    "sort_order" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deals" (
    "id" TEXT NOT NULL,
    "trader_id" TEXT NOT NULL,
    "category_id" INTEGER NOT NULL,
    "title_ar" TEXT NOT NULL,
    "title_en" TEXT NOT NULL,
    "description_ar" TEXT,
    "description_en" TEXT,
    "discount_pct" DOUBLE PRECISION NOT NULL,
    "original_price" DOUBLE PRECISION NOT NULL,
    "image_url" TEXT,
    "max_redemptions" INTEGER NOT NULL DEFAULT 0,
    "redeemed_count" INTEGER NOT NULL DEFAULT 0,
    "expiry_date" TIMESTAMP(3) NOT NULL,
    "tier" "DealTier" NOT NULL DEFAULT 'basic',
    "status" "DealStatus" NOT NULL DEFAULT 'active',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "deals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "claims" (
    "id" TEXT NOT NULL,
    "deal_id" TEXT NOT NULL,
    "consumer_id" TEXT NOT NULL,
    "qr_token" TEXT NOT NULL,
    "status" "ClaimStatus" NOT NULL DEFAULT 'claimed',
    "claimed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "redeemed_at" TIMESTAMP(3),

    CONSTRAINT "claims_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ratings" (
    "id" TEXT NOT NULL,
    "claim_id" TEXT NOT NULL,
    "trader_id" TEXT NOT NULL,
    "consumer_id" TEXT NOT NULL,
    "stars" INTEGER NOT NULL,
    "comment" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ratings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "message_ar" TEXT NOT NULL,
    "message_en" TEXT NOT NULL,
    "read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" TEXT NOT NULL,
    "trader_id" TEXT NOT NULL,
    "deal_id" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "tier" "DealTier" NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "price_cache" (
    "id" TEXT NOT NULL,
    "product_name" TEXT NOT NULL,
    "category_id" INTEGER NOT NULL,
    "market_price_min" DOUBLE PRECISION,
    "market_price_max" DOUBLE PRECISION,
    "market_price_avg" DOUBLE PRECISION,
    "verdict" TEXT,
    "confidence" TEXT,
    "sources" JSONB,
    "raw_response" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "price_cache_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ai_price_logs" (
    "id" TEXT NOT NULL,
    "deal_id" TEXT,
    "trader_id" TEXT NOT NULL,
    "trader_price" DOUBLE PRECISION NOT NULL,
    "trader_discount_pct" DOUBLE PRECISION NOT NULL,
    "ai_suggested_price" DOUBLE PRECISION,
    "ai_verdict" TEXT,
    "trader_accepted_suggestion" BOOLEAN,
    "final_posted_price" DOUBLE PRECISION,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_price_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "categories_slug_key" ON "categories"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "claims_qr_token_key" ON "claims"("qr_token");

-- CreateIndex
CREATE UNIQUE INDEX "ratings_claim_id_key" ON "ratings"("claim_id");

-- AddForeignKey
ALTER TABLE "trader_profiles" ADD CONSTRAINT "trader_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trader_profiles" ADD CONSTRAINT "trader_profiles_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deals" ADD CONSTRAINT "deals_trader_id_fkey" FOREIGN KEY ("trader_id") REFERENCES "trader_profiles"("user_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deals" ADD CONSTRAINT "deals_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "claims" ADD CONSTRAINT "claims_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "claims" ADD CONSTRAINT "claims_consumer_id_fkey" FOREIGN KEY ("consumer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ratings" ADD CONSTRAINT "ratings_claim_id_fkey" FOREIGN KEY ("claim_id") REFERENCES "claims"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ratings" ADD CONSTRAINT "ratings_trader_id_fkey" FOREIGN KEY ("trader_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ratings" ADD CONSTRAINT "ratings_consumer_id_fkey" FOREIGN KEY ("consumer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_trader_id_fkey" FOREIGN KEY ("trader_id") REFERENCES "trader_profiles"("user_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "price_cache" ADD CONSTRAINT "price_cache_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_price_logs" ADD CONSTRAINT "ai_price_logs_trader_id_fkey" FOREIGN KEY ("trader_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_price_logs" ADD CONSTRAINT "ai_price_logs_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "deals"("id") ON DELETE SET NULL ON UPDATE CASCADE;
