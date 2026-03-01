import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import {
  CreateProductDto,
  CreateReviewDto,
} from "../../application/dto/marketplace.dto";
import {
  ListProductsUseCase,
  ListProductsBySellerUseCase,
  GetProductByIdUseCase,
  CreateProductUseCase,
  ListReviewsUseCase,
  CreateOrUpdateReviewUseCase,
  UploadProductImageUseCase,
} from "../../application/use-cases/marketplace.use-cases";

@ApiTags("marketplace")
@ApiBearerAuth("JWT-auth")
@Controller("marketplace")
export class MarketplaceController {
  constructor(
    private readonly listProductsUC: ListProductsUseCase,
    private readonly listBySellerUC: ListProductsBySellerUseCase,
    private readonly getProductUC: GetProductByIdUseCase,
    private readonly createProductUC: CreateProductUseCase,
    private readonly listReviewsUC: ListReviewsUseCase,
    private readonly createReviewUC: CreateOrUpdateReviewUseCase,
    private readonly uploadImageUC: UploadProductImageUseCase,
  ) {}

  @Get("products")
  @ApiOperation({ summary: "List products" })
  async getProducts(
    @Query("limit") limit?: string,
    @Query("category") category?: string,
  ) {
    const result = await this.listProductsUC.execute({
      limit: limit ? parseInt(limit, 10) : 20,
      category,
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }

  @Get("products/mine")
  @ApiOperation({ summary: "List my products" })
  async getMyProducts(@Request() req: { user: { id: string } }) {
    const result = await this.listBySellerUC.execute(req.user.id);
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }

  @Get("products/:id")
  @ApiOperation({ summary: "Get product by ID" })
  async getProductById(@Param("id") id: string) {
    const result = await this.getProductUC.execute(id);
    if (result.isFailure) throw new NotFoundException(result.error);
    return result.value;
  }

  @Get("products/:id/reviews")
  @ApiOperation({ summary: "Get product reviews" })
  async getProductReviews(@Param("id") id: string) {
    const result = await this.listReviewsUC.execute(id);
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }

  @Post("products/:id/reviews")
  @ApiOperation({ summary: "Create or update review" })
  async createReview(
    @Request() req: { user: { id: string; fullName?: string } },
    @Param("id") productId: string,
    @Body() dto: CreateReviewDto,
  ) {
    const result = await this.createReviewUC.execute({
      productId,
      userId: req.user.id,
      userName: req.user.fullName ?? "User",
      dto,
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }

  @Post("products/upload-image")
  @UseInterceptors(FileInterceptor("file"))
  @ApiOperation({ summary: "Upload product image" })
  async uploadImage(
    @UploadedFile() file?: { buffer: Buffer; mimetype: string },
  ) {
    if (!file?.buffer) throw new BadRequestException("No file provided");
    const result = await this.uploadImageUC.execute({
      buffer: file.buffer,
      mimetype: file.mimetype,
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return { imageUrl: result.value };
  }

  @Post("products")
  @ApiOperation({ summary: "Create product" })
  async create(
    @Request() req: { user: { id: string } },
    @Body() dto: CreateProductDto,
  ) {
    const result = await this.createProductUC.execute({
      userId: req.user.id,
      dto,
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }
}
