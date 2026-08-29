// Stub implementations for MinGW CRT symbols needed by dllcrt2.o
// These are never actually called (we skip CRT init with -nostartfiles)
void _amsg_exit(int x) { (void)x; }
void _pei386_runtime_relocator(void) {}
int _initialize_onexit_table(void* x) { (void)x; return 0; }
int _initterm_e(void** a, void** b) { (void)a; (void)b; return 0; }
void _initterm(void** a, void** b) { (void)a; (void)b; }
void __main(void) {}
void _execute_onexit_table(void* x) { (void)x; }
int _register_onexit_function(void* a, void* b) { (void)a; (void)b; return 0; }
int __native_dllmain_reason = 0;
int __mingw_app_type = 1;
void* __dyn_tls_init_callback = 0;
void* __xc_a = 0;
void* __xc_z = 0;
void* __xi_a = 0;
void* __xi_z = 0;
int __native_startup_state = 0;
void* __native_startup_lock = 0;
