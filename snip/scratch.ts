#!/usr/bin/env ts-node --files -D6133 -D7006 -D7017 -D6192
// 6113 - unused things, 7006, 7017 - implicit any type
// 6192 - unused imports

async function main () {
  console.log('...')
}

function logError (err: Error) {
  console.log(`Unhandled promise rejection: ${err.message}`)
  console.log(`Stack trace: ${err.stack}`)
  process.exit(1)
}

process.on('unhandledRejection', logError)

main().catch(logError)
