import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document } from "mongoose";

export type ExternalWebsiteDocument = ExternalWebsite & Document;

@Schema({ _id: false })
export class ScrapeConfig {
  @Prop({ default: "" })
  categoriesUrl?: string;

  @Prop({ default: "" })
  productListSelector?: string;

  @Prop({ default: "" })
  productLinkSelector?: string;

  @Prop({ default: "" })
  productDetailSelectors?: string;
}

export const ScrapeConfigSchema = SchemaFactory.createForClass(ScrapeConfig);

@Schema({ _id: false })
export class FormFieldMapping {
  @Prop()
  appFieldName!: string;

  @Prop()
  siteSelector!: string;

  @Prop({ default: "input" })
  type?: string;
}

export const FormFieldMappingSchema =
  SchemaFactory.createForClass(FormFieldMapping);

@Schema({ timestamps: true })
export class ExternalWebsite {
  @Prop({ required: true, unique: true })
  slug!: string;

  @Prop({ required: true })
  name!: string;

  @Prop({ required: true })
  baseUrl!: string;

  @Prop({ default: true })
  isActive!: boolean;

  @Prop({ type: ScrapeConfigSchema, default: () => ({}) })
  scrapeConfig?: ScrapeConfig;

  @Prop({ type: [FormFieldMappingSchema], default: [] })
  formFieldMapping?: FormFieldMapping[];

  @Prop({ default: "" })
  submitButtonSelector?: string;

  @Prop({ default: "" })
  formActionUrl?: string;

  @Prop({ default: 60 })
  refreshIntervalMinutes?: number;

  createdAt?: Date;
  updatedAt?: Date;
}

export const ExternalWebsiteSchema =
  SchemaFactory.createForClass(ExternalWebsite);
