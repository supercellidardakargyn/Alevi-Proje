export { createApp } from './app';

if (require.main === module) {
  void import('./server');
}
