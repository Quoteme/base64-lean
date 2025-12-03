#include <lean/lean.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>
#include <openssl/evp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <zlib.h>

//
// Encode a string to base64
lean_obj_res lean_base64_encode(lean_obj_arg str) {
  const char *input = lean_string_cstr(str);
  size_t input_len = strlen(input);

  BIO *bio, *b64;
  BUF_MEM *buffer_ptr;

  // Create base64 filter and push it onto a memory BIO
  b64 = BIO_new(BIO_f_base64());
  bio = BIO_new(BIO_s_mem());
  bio = BIO_push(b64, bio);

  // Remove newline characters from output
  BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);

  // Write input string
  BIO_write(bio, input, input_len);
  BIO_flush(bio);

  // Get pointer to the memory buffer
  BIO_get_mem_ptr(bio, &buffer_ptr);

  // Create Lean string from result, the result is copied
  lean_obj_res result =
      lean_mk_string_from_bytes(buffer_ptr->data, buffer_ptr->length);

  // Free all BIO objects
  BIO_free_all(bio);

  return result;
}

// Decode a base64 string
lean_obj_res lean_base64_decode(lean_obj_arg str) {
  const char *input = lean_string_cstr(str);
  size_t input_len = strlen(input);

  BIO *bio, *b64;

  // Allocate buffer for decoded data. Max size is input length, though it will
  // always be less.
  char *buffer = (char *)malloc(input_len);
  if (!buffer) {
    return lean_box(0); // Return None on allocation failure
  }

  // Create memory BIO with the base64 string as input
  bio = BIO_new_mem_buf(input, input_len);
  b64 = BIO_new(BIO_f_base64());
  bio = BIO_push(b64, bio);

  // Disable newline filtering for reading
  BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);

  // Read and decode
  int decoded_len = BIO_read(bio, buffer, input_len);

  BIO_free_all(bio);

  if (decoded_len <= 0) {
    free(buffer);
    return lean_box(0); // Return None on decode failure (or empty string for 0)
  }

  // Create Lean string from decoded data
  lean_obj_res decoded_str = lean_mk_string_from_bytes(buffer, decoded_len);
  free(buffer);

  // Return Some(decoded_str)
  lean_obj_res some_obj = lean_alloc_ctor(1, 1, 0);
  lean_ctor_set(some_obj, 0, decoded_str);

  return some_obj;
}
