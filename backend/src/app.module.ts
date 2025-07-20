import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { DatabaseModule } from "./database/database.module";
import { StatisticsModule } from "./statistics/statistics.module";
import { HealthModule } from "./health/health.module";
import { QueriesModule } from "./queries/queries.module";
import { ActivityModule } from "./activity/activity.module";
import { DataManagementModule } from "./data-management/data-management.module";

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    DatabaseModule,
    StatisticsModule,
    HealthModule,
    QueriesModule,
    ActivityModule,
    DataManagementModule,
  ],
})
export class AppModule {}
