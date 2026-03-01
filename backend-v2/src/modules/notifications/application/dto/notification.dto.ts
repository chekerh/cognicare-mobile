import { IsString, IsOptional, IsObject } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class CreateNotificationDto {
  @ApiProperty() @IsString() type!: string;
  @ApiProperty() @IsString() title!: string;
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  description?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsObject() data?: Record<
    string,
    unknown
  >;
}

export class NotificationOutputDto {
  id!: string;
  type!: string;
  title!: string;
  description!: string;
  read!: boolean;
  data?: Record<string, unknown>;
  createdAt?: string;
}
