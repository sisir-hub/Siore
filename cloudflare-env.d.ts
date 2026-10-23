declare namespace Cloudflare {
  interface Env {
    COURIER_ENCRYPTION_KEY?: string;
    DB?: D1Database;
    BUCKET?: R2Bucket;
  }
}
