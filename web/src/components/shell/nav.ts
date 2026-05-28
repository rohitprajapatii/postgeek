import {
  Activity,
  BarChart3,
  Database,
  Gauge,
  HeartPulse,
  Table2,
  type LucideIcon,
} from "lucide-react";

export interface NavItem {
  label: string;
  href: string;
  icon: LucideIcon;
  description: string;
}

export const navItems: NavItem[] = [
  {
    label: "Overview",
    href: "/dashboard",
    icon: Gauge,
    description: "Database vitals at a glance",
  },
  {
    label: "Activity",
    href: "/activity",
    icon: Activity,
    description: "Live sessions, locks & blocks",
  },
  {
    label: "Queries",
    href: "/queries",
    icon: Database,
    description: "Slow queries & workload",
  },
  {
    label: "Statistics",
    href: "/statistics",
    icon: BarChart3,
    description: "Tables, indexes & I/O metrics",
  },
  {
    label: "Health",
    href: "/health",
    icon: HeartPulse,
    description: "Indexes, bloat & cache",
  },
  {
    label: "Data Studio",
    href: "/data",
    icon: Table2,
    description: "Browse, query & inspect data",
  },
];
