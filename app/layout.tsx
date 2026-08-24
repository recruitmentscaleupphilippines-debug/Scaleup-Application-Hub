import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = { title: "Scale Up | Recruitment Hub", description: "Recruitment operations and candidate experience CRM" };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
