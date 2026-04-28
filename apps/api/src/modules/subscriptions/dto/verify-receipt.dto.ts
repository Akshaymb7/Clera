import { IsEnum, IsString } from 'class-validator';

export enum SubscriptionPlatform {
  ios = 'ios',
  android = 'android',
}

export class VerifyReceiptDto {
  @IsEnum(SubscriptionPlatform)
  platform: SubscriptionPlatform;

  @IsString()
  productId: string;

  @IsString()
  receipt: string; // base64 receipt (iOS) or purchase token (Android)
}
