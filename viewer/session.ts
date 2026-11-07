// Session storage, read through typed parse functions. It can be unavailable,
// as in some private windows, so reading then gives null and writing does
// nothing.

/** The item under the key, parsed, or null if it's missing or malformed. */
export function readSession<T>({
  key,
  parse,
}: {
  key: string;
  parse: (value: unknown) => T | null;
}): T | null {
  try {
    const item = sessionStorage.getItem(key);
    return item === null ? null : parse(JSON.parse(item));
  } catch {
    return null;
  }
}

export function writeSession({ key, value }: { key: string; value: unknown }) {
  try {
    sessionStorage.setItem(key, JSON.stringify(value));
  } catch {}
}
