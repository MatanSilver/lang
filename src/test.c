#include "test.h"

int main(int argc, char **argv) {
	assert_err_list_t *assert_err_list = assert_err_list_new();
	for (int i = 0; i < 12; i++) {
		char buf[256];
		sprintf(buf, "%d != %d <-- should never happen", i, i); //should all pass
		assert_expr(assert_err_list, true, "simple test", buf);
	}
	for (int i = 0; i < 257; i++) {
		char buf[256];
		sprintf(buf, "%d != %d", i, i+1);
		assert_expr(assert_err_list, i == i+1, "simple test", buf);
	}
	assert_expr(assert_err_list, 1 == 0, "simple test 1", "1 != 0");
	assert_expr(assert_err_list, 0 == 0, "simple test 2", "0 != 0 ???");
	assert_expr(assert_err_list, 2 == 1, "simple test 3", "2 != 1");
	assert_err_list_dump(assert_err_list);
	assert_err_list_destroy(assert_err_list);
}
