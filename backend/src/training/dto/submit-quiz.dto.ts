import { IsArray, IsNumber, Min, Max } from 'class-validator';

export class SubmitQuizDto {
  /** Array of selected option indices (0-based) for each question in order */
  @IsArray()
  @IsNumber({}, { each: true })
  @Min(0, { each: true })
  answers: number[];
}
