// Bundles the viewer's script and stylesheet into the Swift package's
// resources.

import { fileURLToPath } from 'node:url';

import { build } from 'esbuild';

const notice = 'Built from viewer/ by `npm run build:viewer`. Edit it there.';

await build({
  absWorkingDir: fileURLToPath(new URL('..', import.meta.url)),
  entryPoints: [
    { in: 'viewer/main.ts', out: 'viewer' },
    { in: 'viewer/styles/main.css', out: 'viewer' },
  ],
  outdir: 'Sources/AllumeWeb/Viewer',
  bundle: true,
  format: 'iife',
  target: 'es2022',
  charset: 'utf8',
  // Set here rather than read from tsconfig.json, which is for type checks
  // only. The bundle runs in strict mode, as TypeScript checks it.
  tsconfigRaw: { compilerOptions: { alwaysStrict: true } },
  banner: { js: `// ${notice}`, css: `/* ${notice} */` },
  logLevel: 'warning',
});
