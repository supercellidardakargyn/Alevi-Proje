import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Can Meydanı Operasyon Merkezi",
  description: "Kullanıcı, moderasyon, içerik ve mesh sağlık yönetimi",
  robots: { index: false, follow: false }
};

export const viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#531827"
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="tr">
      <body>{children}</body>
    </html>
  );
}
