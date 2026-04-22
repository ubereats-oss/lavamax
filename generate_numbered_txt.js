const fs = require('fs');
const path = require('path');
const sourceDir = path.join(__dirname, 'lib');
const outputDir = path.join(__dirname, 'debug_dump');
function ensureDirSync(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}
function numberLines(content) {
  const lines = content.split('\n');
  return lines
    .map((line, index) => {
      const lineNumber = (index + 1).toString().padStart(4, ' ');
      return `${lineNumber}: ${line}`;
    })
    .join('\n');
}
function processDirectory(currentDir) {
  const entries = fs.readdirSync(currentDir, { withFileTypes: true });
  entries.forEach(entry => {
    const fullPath = path.join(currentDir, entry.name);
    const relativePath = path.relative(sourceDir, fullPath);
    const outputPath = path.join(outputDir, relativePath);
    if (entry.isDirectory()) {
      ensureDirSync(outputPath);
      processDirectory(fullPath);
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      const numbered = numberLines(content);
      const outputFilePath = outputPath.replace('.dart', '.txt');
      ensureDirSync(path.dirname(outputFilePath));
      fs.writeFileSync(outputFilePath, numbered, 'utf8');
    }
  });
}
function main() {
  if (!fs.existsSync(sourceDir)) {
    console.error('Pasta lib não encontrada.');
    process.exit(1);
  }
  ensureDirSync(outputDir);
  processDirectory(sourceDir);
  console.log('Arquivos numerados gerados em:');
  console.log(outputDir);
}
main();
