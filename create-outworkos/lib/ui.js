import chalk from "chalk";
import ora from "ora";

export const ok = (msg) => console.log(`  ${chalk.green("\u2713")} ${msg}`);
export const skip = (msg) => console.log(`  ${chalk.yellow("\u2013")} ${msg} (already done)`);
export const fail = (msg) => console.log(`  ${chalk.red("\u2717")} ${msg}`);
export const info = (msg) => console.log(`  ${chalk.bold("\u2192")} ${msg}`);
export const warn = (msg) => console.log(`  ${chalk.yellow("\u26A0")} ${msg}`);

export const header = (num, title) => {
  console.log();
  console.log(chalk.bold(`${num}. ${title}`));
};

export const banner = () => {
  console.log();
  console.log(`  ${chalk.yellow("\u2590\u258C")} ${chalk.bold("Outwork OS Setup")}`);
  console.log(`  ${chalk.dim("A personal operating system for knowledge workers")}`);
  console.log();
};

export const divider = () => {
  console.log(chalk.dim("\u2501".repeat(52)));
};

export const spinner = (text) => ora({ text, indent: 2 }).start();
