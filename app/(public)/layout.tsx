import { PublicFooter } from "@/components/site/public-footer";
import { PublicHeader } from "@/components/site/public-header";

export default function PublicLayout({ children }: LayoutProps<"/">) {
  return (
    <div className="flex min-h-screen flex-col">
      <PublicHeader />
      <main className="flex-1">{children}</main>
      <PublicFooter />
    </div>
  );
}
