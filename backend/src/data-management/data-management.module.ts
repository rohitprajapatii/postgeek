import { Module } from "@nestjs/common";
import { DataManagementController } from "./data-management.controller";
import { DataManagementService } from "./data-management.service";
import { DatabaseModule } from "../database/database.module";

@Module({
  imports: [DatabaseModule],
  controllers: [DataManagementController],
  providers: [DataManagementService],
  exports: [DataManagementService],
})
export class DataManagementModule {}
