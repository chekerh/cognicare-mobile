import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsString,
  ValidateNested,
} from 'class-validator';
import { plainToInstance, Transform, Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class ConfirmedMappingDto {
  @ApiProperty({ example: 'full name' })
  @IsString()
  @IsNotEmpty()
  excelHeader!: string;

  @ApiProperty({ example: 'fullName' })
  @IsString()
  @IsNotEmpty()
  dbField!: string;
}

export class ConfirmImportDto {
  @ApiProperty({
    description: 'Import type',
    enum: ['staff', 'families', 'children', 'families_children'],
  })
  @IsEnum(['staff', 'families', 'children', 'families_children'])
  importType!: string;

  @ApiProperty({
    description: 'Column mappings confirmed by the user',
    type: [ConfirmedMappingDto],
  })
  @Transform(({ value }): ConfirmedMappingDto[] => {
    const parsed = typeof value === 'string' ? JSON.parse(value) : value;
    return Array.isArray(parsed)
      ? parsed.map((item: Record<string, unknown>) =>
          plainToInstance(ConfirmedMappingDto, item),
        )
      : [];
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ConfirmedMappingDto)
  mappings!: ConfirmedMappingDto[];
}
