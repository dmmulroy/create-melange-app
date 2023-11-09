// This is a real commander.js example, and is what we're aiming
// to generate with melange.
const { program } = require("commander");

program.option("--first").option("-s, --separator <char>");

program.parse();

const options = program.opts();

console.log(options);

// example output:
// bun commaned_example.js -s / --first a/b/c
// { first: true, separator: "/" }
