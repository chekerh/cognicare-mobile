import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model } from "mongoose";
import {
  FraudAnalysis,
  FraudAnalysisDocument,
} from "./schemas/fraud-analysis.schema";

let pipeline: any;

@Injectable()
export class SimilarityService implements OnModuleInit {
  private readonly logger = new Logger(SimilarityService.name);
  private extractor: any = null;
  private isInitialized = false;

  constructor(
    @InjectModel(FraudAnalysis.name)
    private fraudAnalysisModel: Model<FraudAnalysisDocument>,
  ) {}

  async onModuleInit() {
    await this.initializeModel();
  }

  private async initializeModel(): Promise<void> {
    try {
      this.logger.log("Initializing embedding model...");
      const transformers = await import("@xenova/transformers");
      pipeline = transformers.pipeline;
      this.extractor = await pipeline(
        "feature-extraction",
        "Xenova/all-MiniLM-L6-v2",
      );
      this.isInitialized = true;
      this.logger.log("Embedding model initialized successfully");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      this.logger.error(`Failed to initialize embedding model: ${message}`);
    }
  }

  isReady(): boolean {
    return this.isInitialized && this.extractor !== null;
  }

  async generateEmbedding(text: string): Promise<number[]> {
    if (!this.isReady()) {
      this.logger.warn(
        "Embedding model not initialized, returning empty embedding",
      );
      return [];
    }
    try {
      const truncatedText = text.slice(0, 2000);
      const output = (await this.extractor(truncatedText, {
        pooling: "mean",
        normalize: true,
      })) as { data: ArrayLike<number> };
      const embedding = Array.from(output.data);
      this.logger.debug(
        `Generated embedding with ${embedding.length} dimensions`,
      );
      return embedding;
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      this.logger.error(`Failed to generate embedding: ${message}`);
      return [];
    }
  }

  cosineSimilarity(vecA: number[], vecB: number[]): number {
    if (vecA.length === 0 || vecB.length === 0) return 0;
    if (vecA.length !== vecB.length) {
      this.logger.warn("Vector dimension mismatch");
      return 0;
    }

    let dotProduct = 0,
      normA = 0,
      normB = 0;
    for (let i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    const magnitude = Math.sqrt(normA) * Math.sqrt(normB);
    if (magnitude === 0) return 0;
    const similarity = dotProduct / magnitude;
    return Math.max(0, Math.min(1, (similarity + 1) / 2));
  }

  async findMaxSimilarity(
    embedding: number[],
    excludeId?: string,
  ): Promise<{
    similarityScore: number;
    similarityRisk: "LOW" | "MEDIUM" | "HIGH";
  }> {
    if (embedding.length === 0)
      return { similarityScore: 0, similarityRisk: "LOW" };

    try {
      const query: Record<string, unknown> = {
        embedding: { $exists: true, $ne: [] },
      };
      if (excludeId) query._id = { $ne: excludeId };

      const previousSubmissions = await this.fraudAnalysisModel
        .find(query)
        .select("embedding isRejected")
        .lean()
        .exec();

      if (previousSubmissions.length === 0) {
        return { similarityScore: 0, similarityRisk: "LOW" };
      }

      let maxSimilarity = 0;
      let foundSimilarRejected = false;

      for (const submission of previousSubmissions) {
        if (!submission.embedding || submission.embedding.length === 0)
          continue;
        const similarity = this.cosineSimilarity(
          embedding,
          submission.embedding,
        );
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          if (submission.isRejected && similarity > 0.85)
            foundSimilarRejected = true;
        }
      }

      let similarityRisk: "LOW" | "MEDIUM" | "HIGH" = "LOW";
      if (maxSimilarity > 0.85) similarityRisk = "HIGH";
      else if (maxSimilarity > 0.7) similarityRisk = "MEDIUM";

      this.logger.log(
        `Max similarity: ${maxSimilarity.toFixed(3)}, Risk: ${similarityRisk}${foundSimilarRejected ? " (similar to rejected)" : ""}`,
      );

      return { similarityScore: maxSimilarity, similarityRisk };
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      this.logger.error(`Failed to compute similarity: ${message}`);
      return { similarityScore: 0, similarityRisk: "LOW" };
    }
  }

  getSimilarityRisk(score: number): "LOW" | "MEDIUM" | "HIGH" {
    if (score > 0.85) return "HIGH";
    if (score > 0.7) return "MEDIUM";
    return "LOW";
  }
}
