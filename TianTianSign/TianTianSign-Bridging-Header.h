#ifndef Bridging_Header_h
#define Bridging_Header_h

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/// 调用 zsign 重签引擎。argc/argv 同命令行参数。
/// 返回 0 成功，非 0 失败。
int zsign_ios_run(int argc, const char** argv);

#ifdef __cplusplus
}
#endif

#endif /* Bridging_Header_h */
