import { Controller, Get, Post, Query, ParseIntPipe, DefaultValuePipe, HttpCode, HttpStatus } from '@nestjs/common';
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
  @HttpCode(HttpStatus.OK)
  resetQueryStats() {
    return this.queriesService.resetQueryStats();
  }

  @Post('enable-extension')
  @HttpCode(HttpStatus.OK)
  enablePgStatStatements() {
    return this.queriesService.enablePgStatStatements();
  }
}