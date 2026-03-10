#!/usr/bin/env -S v run

// build.vsh — Build script for multi-agent
// Usage:
//   v run build.vsh           # Build (release)
//   v run build.vsh debug     # Build with debug symbols
//   v run build.vsh test      # Build + run unit tests
//   v run build.vsh clean     # Remove build artifacts
//   v run build.vsh all       # Build + test

import os

const bin_name = 'multi_agent'
const src_dir  = 'src'
const version  = '0.1.0'

fn step(msg string) {
	println('\n\x1b[36m▶ ${msg}\x1b[0m')
}

fn ok(msg string) {
	println('\x1b[32m✔ ${msg}\x1b[0m')
}

fn fail(msg string) {
	println('\x1b[31m✘ ${msg}\x1b[0m')
}

fn build(flags string) bool {
	cmd := 'v ${flags} -o ${bin_name} ${src_dir}'
	println('  ${cmd}')
	res := os.execute(cmd)
	if res.exit_code != 0 {
		fail('Build failed')
		print(res.output)
		return false
	}
	ok('Built → ./${bin_name}  (v${version})')
	return true
}

fn run_tests() bool {
	step('Running unit tests')
	res := os.execute('v test tests/')
	print(res.output)
	if res.exit_code != 0 {
		fail('Tests failed')
		return false
	}
	ok('All tests passed')
	return true
}

fn clean() {
	step('Cleaning build artifacts')
	for f in [bin_name, bin_name + '.exe', 'multi_agent_test', 'multi_agent_test.exe'] {
		if os.exists(f) {
			os.rm(f) or {}
			println('  removed ${f}')
		}
	}
	ok('Clean done')
}

fn main() {
	args := os.args[1..]  // skip script path
	cmd  := if args.len > 0 { args[0] } else { 'release' }

	println('\x1b[1mmulti-agent builder v${version}\x1b[0m')

	match cmd {
		'clean' {
			clean()
		}
		'debug' {
			step('Building (debug)')
			if !build('-g') { exit(1) }
		}
		'test' {
			step('Building (release)')
			if !build('') { exit(1) }
			if !run_tests() { exit(1) }
		}
		'all' {
			step('Building (release)')
			if !build('') { exit(1) }
			if !run_tests() { exit(1) }
		}
		else {
			// default: release build
			step('Building (release)')
			if !build('') { exit(1) }
		}
	}
}
