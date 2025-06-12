import { Controller, Get, Delete, Param, ParseIntPipe } from '@nestjs/common';
import { ActivityService } from './activity.service';

@Controller('activity')
export class ActivityController {
  constructor(private readonly activityService: ActivityService) {}

  @Get('sessions/active')
  getActiveSessions() {
    return this.activityService.getActiveSessions();
  }

  @Get('sessions/idle')
  getIdleSessions() {
    return this.activityService.getIdleSessions();
  }

  @Get('locks')
  getLocks() {
    return this.activityService.getLocks();
  }

  @Get('blocked')
  getBlockedQueries() {
    return this.activityService.getBlockedQueries();
  }

  @Delete('sessions/:pid')
  terminateSession(@Param('pid', ParseIntPipe) pid: number) {
    return this.activityService.terminateSession(pid);
  }
}