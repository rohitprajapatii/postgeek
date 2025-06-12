import { Controller, Get } from '@nestjs/common';
import { HealthService } from './health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  getHealthOverview() {
    return this.healthService.getHealthOverview();
  }

  @Get('missing-indexes')
  getMissingIndexes() {
    return this.healthService.getMissingIndexes();
  }

  @Get('unused-indexes')
  getUnusedIndexes() {
    return this.healthService.getUnusedIndexes();
  }

  @Get('table-bloat')
  getTableBloat() {
    return this.healthService.getTableBloat();
  }
}