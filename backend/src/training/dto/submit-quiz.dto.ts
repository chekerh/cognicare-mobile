import { IsArray, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class SubmitQuizDto {
  /** Array of selected option indices (0-based) for MC/true_false; for fill_blank use textAnswers at same index */
  @IsArray()
  @IsNumber({}, { each: true })
  @Min(-1, { each: true })
  answers: number[];

  /** For fill_blank questions, text answer at index i (same length as answers; omit or '' for non-fill_blank) */
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  textAnswers?: string[];
}
