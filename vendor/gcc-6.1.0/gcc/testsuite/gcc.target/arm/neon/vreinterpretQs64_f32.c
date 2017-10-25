/* Test the `vreinterpretQs64_f32' ARM Neon intrinsic.  */
/* This file was autogenerated by neon-testgen.  */

/* { dg-do assemble } */
/* { dg-require-effective-target arm_neon_ok } */
/* { dg-options "-save-temps -O0" } */
/* { dg-add-options arm_neon } */

#include "arm_neon.h"

void test_vreinterpretQs64_f32 (void)
{
  int64x2_t out_int64x2_t;
  float32x4_t arg0_float32x4_t;

  out_int64x2_t = vreinterpretq_s64_f32 (arg0_float32x4_t);
}
