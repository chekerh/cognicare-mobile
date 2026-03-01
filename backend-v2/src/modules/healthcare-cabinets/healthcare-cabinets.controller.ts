import { Controller, Get } from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import { Public } from "@/shared/decorators/public.decorator";
import { HealthcareCabinetsService } from "./healthcare-cabinets.service";

@ApiTags("Healthcare Cabinets")
@Controller("healthcare-cabinets")
export class HealthcareCabinetsController {
  constructor(private readonly service: HealthcareCabinetsService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: "List all healthcare cabinets" })
  async findAll() {
    return this.service.findAll();
  }

  @Public()
  @Get("refresh")
  @ApiOperation({
    summary: "Refresh list from OpenStreetMap and return updated cabinets",
  })
  async refresh() {
    const { added, total } = await this.service.fetchFromOverpassAndUpsert();
    const cabinets = await this.service.findAll();
    return { added, total, cabinets };
  }
}
