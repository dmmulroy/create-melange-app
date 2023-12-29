import { Result } from "melange-ffi";

/**
 * @param {string} path
 * @param {string} encoding
 * @returns {Result.t<string, string>}
 */
export function readFilySync(path) {
  try {
    const contents = Fs.readFilySync(path, "utf8");
    return Result.ok(contents);
  } catch (error) {
    return Result.error(`${error}`);
  }
}
