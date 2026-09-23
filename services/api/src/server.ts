import { createApp } from './app';
import { config } from './config';

async function main(): Promise<void> {
  const context = await createApp();
  const { app } = context;
  const server = app.listen(config.port, config.host, () => {
    console.log(`API listening on ${config.host}:${config.port}`);
  });

  const shutdown = (signal: string) => {
    console.log(`Received ${signal}; shutting down`);
    void context.close().finally(() => {
      server.close(() => process.exit(0));
    });
    setTimeout(() => process.exit(1), 10_000).unref();
  };
  process.once('SIGTERM', () => shutdown('SIGTERM'));
  process.once('SIGINT', () => shutdown('SIGINT'));
}

main().catch((error) => {
  console.error('Unable to start API', error);
  process.exit(1);
});
