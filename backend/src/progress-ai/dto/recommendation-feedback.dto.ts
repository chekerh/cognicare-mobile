import { IsString, IsOptional, IsIn, IsMongoId, IsBoolean } from 'class-validator';

export class RecommendationFeedbackDto {
  @IsString()
  childId!: string;

  @IsOptional()
  @IsMongoId()
  planId?: string;

  @IsOptional()
  @IsString()
  planType?: string;

  @IsString()
  @IsIn(['approved', 'modified', 'dismissed'])
  action!: 'approved' | 'modified' | 'dismissed';

  @IsOptional()
  @IsString()
  editedText?: string;

  @IsOptional()
  @IsString()
  originalRecommendationText?: string;

  @IsOptional()
  @IsBoolean()
  resultsImproved?: boolean;

  @IsOptional()
  @IsBoolean()
  parentFeedbackHelpful?: boolean;
}
