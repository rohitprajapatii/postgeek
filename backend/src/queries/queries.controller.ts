import { Controller, Get, Post, Query, ParseIntPipe, DefaultValuePipe } from '@nestjs/common';
import { QueriesService } from './queries.service';

@Controller('queries')
export class QueriesController {
  constructor(private readonly queriesService: QueriesService) {}

  @Get('slow')
  getSlowQueries(
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    return this.queriesService.getSlowQueries(limit);
  }

  @Get('stats')
  getQueryStats() {
    return this.queriesService.getQueryStats();
  }

  @Get('types')
  getQueryTypes() {
    return this.queriesService.getQueryTypes();
  }

  @Post('reset')
  resetQueryStats() {
    return this.queriesService.resetQueryStats();
  }
}