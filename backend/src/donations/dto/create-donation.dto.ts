import {
  IsString,
  IsNumber,
  IsBoolean,
  IsArray,
  IsOptional,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateDonationDto {
  @IsString()
  title: string;

  @IsString()
  description: string;

  /** 0: Vêtements, 1: Mobilier, 2: Matériel d'éveil */
  @IsNumber()
  @Min(0)
  @Max(2)
  @Type(() => Number)
  category: number;

  /** 0: Neuf, 1: Très bon état, 2: Bon état */
  @IsNumber()
  @Min(0)
  @Max(2)
  @Type(() => Number)
  condition: number;

  @IsString()
  location: string;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  latitude?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  longitude?: number;

  /** Âge adapté (ex: "0-2 ans", "3-5 ans", "Tous âges") */
  @IsOptional()
  @IsString()
  suitableAge?: string;

  /** true = offre (Je donne), false = demande */
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  isOffer?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUrls?: string[];
}
