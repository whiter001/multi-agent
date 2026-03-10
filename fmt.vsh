#!/usr/bin/env -S v run

// fmt.vsh — Code formatter for multi-agent
// Usage:
//   v run fmt.vsh        # Format all V source files and markdown
//   v run fmt.vsh check  # Check formatting without modifying
//   v run fmt.vsh v      # Format only V source files
//   v run fmt.vsh md     # Format only markdown files

import os

const src_dir = 'src'
const md_files = ['README.md', 'README_zh.md', 'TODO.md']

fn step(msg string) {
	println('\n\x1b[36m▶ ${msg}\x1b[0m')
}

fn ok(msg string) {
	println('\x1b[32m✔ ${msg}\x1b[0m')
}

fn fail(msg string) {
	println('\x1b[31m✘ ${msg}\x1b[0m')
}

fn format_v_files(check_only bool) {
	step('Formatting V source files...')

	v_files := os.walk_ext(src_dir, '.v')
	if v_files.len == 0 {
		ok('No .v files found in ${src_dir}/')
		return
	}

	mut changed := 0
	mut errors := 0

	for file in v_files {
		if check_only {
			res := os.execute('v fmt -c ${file}')
			if res.exit_code != 0 {
				fail('Format check failed: ${file}')
				errors++
			} else {
				ok('OK: ${file}')
			}
		} else {
			res := os.execute('v fmt ${file}')
			if res.exit_code != 0 {
				fail('Failed to format: ${file}')
				errors++
			} else {
				ok('Formatted: ${file}')
				changed++
			}
		}
	}

	if check_only {
		if errors == 0 {
			ok('All V files are properly formatted.')
		} else {
			fail('${errors} V file(s) have formatting issues.')
		}
	} else {
		ok('Formatted ${changed} V file(s).')
	}
}

fn format_md_files(check_only bool) {
	step('Formatting markdown files...')

	mut changed := 0
	mut errors := 0

	for file in md_files {
		if !os.exists(file) {
			continue
		}

		if check_only {
			res := os.execute('npx --yes oxfmt@latest --check ${file}')
			if res.exit_code != 0 {
				fail('Format check failed: ${file}')
				errors++
			} else {
				ok('OK: ${file}')
			}
		} else {
			res := os.execute('npx --yes oxfmt@latest ${file}')
			if res.exit_code != 0 {
				fail('Failed to format: ${file}')
				errors++
			} else {
				ok('Formatted: ${file}')
				changed++
			}
		}
	}

	if check_only {
		if errors == 0 {
			ok('All markdown files are properly formatted.')
		} else {
			fail('${errors} markdown file(s) have formatting issues.')
		}
	} else {
		ok('Formatted ${changed} markdown file(s).')
	}
}

fn main() {
	mut check_only := false
	mut format_v := true
	mut format_md := true

	for arg in os.args[1..] {
		match arg {
			'check' {
				check_only = true
			}
			'v' {
				format_md = false
			}
			'md' {
				format_v = false
			}
			else {}
		}
	}

	if format_v {
		format_v_files(check_only)
	}

	if format_md {
		format_md_files(check_only)
	}
}
