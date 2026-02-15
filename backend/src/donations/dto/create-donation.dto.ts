import { IsString, IsNumber, IsBoolean, IsArray, IsOptional } from 'class-validator';

export class CreateDonationDto {
  @IsString()
  title: string;

  @IsString()
  description: string;

  /** 0: Vêtements, 1: Mobilier, 2: Matériel d'éveil */
  @IsNumber()
  category: number;

  /** 0: Neuf, 1: Très bon état, 2: Bon état */
  @IsNumber()
  condition: number;

  @IsString()
  location: string;

  /** true = offre (Je donne), false = demande */
  @IsOptional()
  @IsBoolean()
  isOffer?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUrls?: string[];
}
