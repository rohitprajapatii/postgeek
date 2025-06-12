import { Controller, Get } from '@nestjs/common';
import { StatisticsService } from './statistics.service';

@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get('overview')
  getDatabaseOverview() {
    return this.statisticsService.getDatabaseOverview();
  }

  @Get('tables')
  getTableStats() {
    return this.statisticsService.getTableStats();
  }

  @Get('indexes')
  getIndexStats() {
    return this.statisticsService.getIndexStats();
  }

  @Get('io')
  getIoStats() {
    return this.statisticsService.getIoStats();
  }

  @Get('bgwriter')
  getBgWriterStats() {
    return this.statisticsService.getBgWriterStats();
  }
}