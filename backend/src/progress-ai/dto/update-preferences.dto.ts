import { IsOptional, IsArray, IsString, IsIn, IsObject } from 'class-validator';

export class UpdateSpecialistPreferencesDto {
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  focusPlanTypes?: string[];

  @IsOptional()
  @IsString()
  @IsIn(['short', 'detailed'])
  summaryLength?: 'short' | 'detailed';

  @IsOptional()
  @IsString()
  @IsIn(['every_session', 'weekly'])
  frequency?: 'every_session' | 'weekly';

  /** Weights per plan type (e.g. { PECS: 1.2, TEACCH: 1.0 }). Higher = more emphasis. */
  @IsOptional()
  @IsObject()
  planTypeWeights?: Record<string, number>;
}
