# 14 - Memory Management

## Overview
Verify memory safety in languages without garbage collection (C, C++, Rust
unsafe blocks, Go CGo). This category is **SKIPPED** for GC languages (Ruby,
Python, JavaScript, Java, C#, Elixir).

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| C/C++ | `src/`, `lib/`, header files, build system |
| Rust (unsafe) | `unsafe` blocks, FFI bindings |
| Go (CGo) | `import "C"` blocks, CGo wrappers |
| C extensions | Ruby C extensions in `ext/`, Python C extensions |

## Checklist Items

### MM-01: Buffer Overflow
- **What to check:** Array/buffer bounds checked before access
- **Detection patterns:**
  - Search: `strcpy\(|strcat\(|sprintf\(|gets\(` (unsafe C string functions)
  - Search: `scanf\(.*%s` without width limit
  - Search: `memcpy\(|memmove\(` without bounds validation
  - Search: array index from user input without bounds check
  - Files: `**/*.c`, `**/*.cpp`, `**/*.h`, `ext/**/*`
- **Secure pattern:**
  ```c
  // Use safe alternatives
  strncpy(dest, src, sizeof(dest) - 1);
  dest[sizeof(dest) - 1] = '\0';
  snprintf(buf, sizeof(buf), "%s", input);
  ```
- **Severity:** Critical
- **CWE:** CWE-120
- **OWASP Top 10:** A03:2021-Injection

### MM-02: Use After Free
- **What to check:** Pointers not used after memory is freed
- **Detection patterns:**
  - Search: `free\(` followed by use of same pointer variable
  - Search: pointer dereference after `free` or `delete`
  - Search: `unsafe` blocks in Rust with raw pointer manipulation
  - Files: `**/*.c`, `**/*.cpp`, `**/*.rs`
- **Secure pattern:**
  ```c
  free(ptr);
  ptr = NULL;  // Prevent use-after-free
  ```
- **Severity:** Critical
- **CWE:** CWE-416
- **OWASP Top 10:** A03:2021-Injection

### MM-03: Double Free
- **What to check:** Memory not freed twice
- **Detection patterns:**
  - Search: multiple `free\(` calls on same variable
  - Search: `free` in error handling paths that may double-free
  - Search: conditional free without NULL check
  - Files: `**/*.c`, `**/*.cpp`
- **Secure pattern:**
  ```c
  if (ptr) {
      free(ptr);
      ptr = NULL;
  }
  ```
- **Severity:** Critical
- **CWE:** CWE-415
- **OWASP Top 10:** A03:2021-Injection

### MM-04: Integer Overflow Leading to Buffer Overflow
- **What to check:** Integer arithmetic checked before memory allocation
- **Detection patterns:**
  - Search: `malloc\(.*\*` with user-controlled size
  - Search: `calloc\(` with user-controlled count/size
  - Search: `realloc\(` with user-controlled size
  - Search: size calculations without overflow check before allocation
  - Files: `**/*.c`, `**/*.cpp`
- **Secure pattern:**
  ```c
  // Check for overflow before allocation
  if (count > 0 && size > SIZE_MAX / count) {
      return ERROR_OVERFLOW;
  }
  void *buf = calloc(count, size);
  ```
- **Severity:** Critical
- **CWE:** CWE-190
- **OWASP Top 10:** A03:2021-Injection

### MM-05: Uninitialized Memory Read
- **What to check:** Variables initialized before use
- **Detection patterns:**
  - Search: variable declaration without initialization followed by use
  - Search: `malloc\(` without subsequent `memset` or initialization
  - Search: struct fields used before assignment
  - Files: `**/*.c`, `**/*.cpp`
- **Secure pattern:**
  ```c
  // Initialize on declaration
  int result = 0;
  // Or use calloc (zero-initialized)
  void *buf = calloc(1, size);
  ```
- **Severity:** High
- **CWE:** CWE-457
- **OWASP Top 10:** A04:2021-Insecure Design

### MM-06: Null Pointer Dereference
- **What to check:** Pointers checked for NULL before dereference
- **Detection patterns:**
  - Search: `malloc\(|calloc\(|realloc\(` return value not checked
  - Search: function return values used without NULL check
  - Search: pointer arithmetic without NULL guard
  - Files: `**/*.c`, `**/*.cpp`
- **Secure pattern:**
  ```c
  void *buf = malloc(size);
  if (buf == NULL) {
      return ERROR_OOM;
  }
  ```
- **Severity:** High
- **CWE:** CWE-476
- **OWASP Top 10:** A04:2021-Insecure Design

### MM-07: Stack Overflow
- **What to check:** Deep recursion bounded, large stack allocations avoided
- **Detection patterns:**
  - Search: recursive functions without depth limit
  - Search: `alloca\(` with user-controlled size
  - Search: large arrays on stack (`char buf[1048576]`)
  - Files: `**/*.c`, `**/*.cpp`
- **Secure pattern:**
  ```c
  // Limit recursion depth
  int parse(data_t *data, int depth) {
      if (depth > MAX_DEPTH) return ERROR_TOO_DEEP;
      return parse(data->child, depth + 1);
  }
  ```
- **Severity:** High
- **CWE:** CWE-674
- **OWASP Top 10:** A04:2021-Insecure Design

### MM-08: Heap Spray
- **What to check:** Heap allocations bounded to prevent heap spray attacks
- **Detection patterns:**
  - Search: unbounded allocation loops from user input
  - Search: `malloc` in loops without total allocation tracking
  - Search: user-controlled allocation count without limit
  - Files: `**/*.c`, `**/*.cpp`
- **Secure pattern:**
  ```c
  #define MAX_ALLOCS 1000
  if (user_count > MAX_ALLOCS) return ERROR_TOO_MANY;
  ```
- **Severity:** Medium
- **CWE:** CWE-122
- **OWASP Top 10:** A04:2021-Insecure Design

### MM-09: Format String Vulnerabilities
- **What to check:** User input never used as format string
- **Detection patterns:**
  - Search: `printf\(user_input` or `printf\(buf` without format string
  - Search: `fprintf\(.*,\s*user` without format string
  - Search: `syslog\(.*,\s*user` without format string
  - Search: `NSLog\(user` (Objective-C)
  - Files: `**/*.c`, `**/*.cpp`, `**/*.m`
- **Secure pattern:**
  ```c
  // Always use format string
  printf("%s", user_input);  // NOT printf(user_input)
  ```
- **Severity:** Critical
- **CWE:** CWE-134
- **OWASP Top 10:** A03:2021-Injection

### MM-10: Race Conditions in Memory Access
- **What to check:** Shared memory accessed under proper synchronization
- **Detection patterns:**
  - Search: global/shared variables modified without mutex/lock
  - Search: `pthread_mutex` usage completeness
  - Search: `unsafe impl Send|unsafe impl Sync` in Rust
  - Search: `//go:nosplit` or `sync.Mutex` patterns in Go
  - Files: `**/*.c`, `**/*.cpp`, `**/*.rs`, `**/*.go`
- **Secure pattern:**
  ```c
  pthread_mutex_lock(&data_mutex);
  shared_data = new_value;
  pthread_mutex_unlock(&data_mutex);
  ```
- **Severity:** High
- **CWE:** CWE-362
- **OWASP Top 10:** A04:2021-Insecure Design

### MM-11: Memory Leak (Persistent)
- **What to check:** Allocated memory freed in all code paths
- **Detection patterns:**
  - Search: `malloc|calloc|new` without corresponding `free|delete`
  - Search: early returns without freeing allocated memory
  - Search: error paths that skip cleanup
  - Files: `**/*.c`, `**/*.cpp`
- **Secure pattern:**
  ```c
  // Use goto cleanup pattern
  void *buf = malloc(size);
  if (!buf) goto cleanup;
  // ... work ...
  cleanup:
      free(buf);
      return result;
  ```
- **Severity:** Medium
- **CWE:** CWE-401
- **OWASP Top 10:** A04:2021-Insecure Design

### MM-12: Off-by-One in Buffer Operations
- **What to check:** Buffer operations account for null terminator and exact sizes
- **Detection patterns:**
  - Search: `strlen` used as buffer size without +1 for null terminator
  - Search: loop conditions using `<=` instead of `<` for array bounds
  - Search: `fgets\(buf, sizeof(buf)` (correct) vs `fgets\(buf, sizeof(buf)+1` (wrong)
  - Files: `**/*.c`, `**/*.cpp`
- **Secure pattern:**
  ```c
  char *copy = malloc(strlen(src) + 1);  // +1 for null terminator
  strcpy(copy, src);
  ```
- **Severity:** High
- **CWE:** CWE-193
- **OWASP Top 10:** A03:2021-Injection

### MM-13: ROP Gadget Exposure
- **What to check:** Binary hardening flags enabled (ASLR, DEP/NX, stack canaries)
- **Detection patterns:**
  - Search: `-fno-stack-protector` in build flags (bad)
  - Search: `-z execstack` in linker flags (bad)
  - Search: `no-pie|nopie` in build flags (bad)
  - Search: compiler hardening flags present (`-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`)
  - Files: `Makefile`, `CMakeLists.txt`, `configure.ac`, `build.rs`
- **Secure pattern:**
  ```makefile
  CFLAGS += -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE
  LDFLAGS += -z relro -z now -pie
  ```
- **Severity:** Medium
- **CWE:** CWE-119
- **OWASP Top 10:** A04:2021-Insecure Design

### MM-14: ASLR/DEP Compatibility
- **What to check:** Application compatible with ASLR and DEP
- **Detection patterns:**
  - Search: `-no-pie` or position-dependent code
  - Search: `mmap.*PROT_EXEC` with `MAP_FIXED` (may break ASLR)
  - Search: JIT or dynamic code generation without W^X enforcement
  - Files: `Makefile`, `CMakeLists.txt`, `**/*.c`, `**/*.cpp`
- **Secure pattern:** Compile with PIE enabled. Don't use fixed memory addresses.
- **Severity:** Medium
- **CWE:** CWE-119
- **OWASP Top 10:** A04:2021-Insecure Design

### MM-15: Secure Memory Wiping for Secrets
- **What to check:** Sensitive data (keys, passwords) zeroed after use
- **Detection patterns:**
  - Search: `memset\(.*0.*password|memset\(.*0.*key` (may be optimized out)
  - Search: `explicit_bzero|SecureZeroMemory|OPENSSL_cleanse` (good)
  - Search: password/key buffers without cleanup
  - Search: `zeroize` crate usage in Rust (good)
  - Files: `**/*.c`, `**/*.cpp`, `**/*.rs`
- **Secure pattern:**
  ```c
  // Use explicit_bzero (not optimized away by compiler)
  explicit_bzero(password_buf, sizeof(password_buf));
  // Or volatile pointer
  volatile char *p = password_buf;
  while (len--) *p++ = 0;
  ```
- **Severity:** Medium
- **CWE:** CWE-244
- **OWASP Top 10:** A02:2021-Cryptographic Failures
