//
//  MessageCodes.h
//  riak_pb-objc
//
//  Created by Scott Gonyea on 8/30/10.
//
#ifndef _PABST_MC_
# define _PABST_MC_
/*
 * Message/Packet Headers
 */
#   define MSG_LENGTH_SIZE              4
#   define MSG_CODE_SIZE                1
#   define MC_SIZE                      1
#   define MSG_NIL_SIZE                 1
#   define MSG_PAD_SIZE                 MSG_LENGTH_SIZE + MSG_CODE_SIZE
#   define MSG_PAD_AND_NIL_SIZE         MSG_PAD_SIZE    + MSG_NIL_SIZE
#   define MSG_SIZE_DISCOUNT            MSG_LENGTH_SIZE
#   define MSG_LENGTH_OFFSET            0
#   define ML_OFFSET                    MSG_LENGTH_OFFSET
#   define MSG_CODE_OFFSET              MSG_LENGTH_SIZE
#   define MC_OFFSET                    MSG_CODE_OFFSET
#   define MSG_OFFSET                   MSG_PAD_SIZE
/*
 * Macros
 */
#   define Serialize_Request(request, size, pbuff)  (pbuff.SerializeToArray(request + MSG_OFFSET, size))
#   define CStr_End_With_Nil(request, length)       (request[ length-1 ] = nil)
#   define receiveResponse(len, code, msg) ({                                             \
                msgLength = [[OFNumber numberWithUInt32:[socket readBigEndianInt32]]      \
                             numberByDecreasing];                                         \
                code      = [OFNumber numberWithUInt8:[socket readInt8]];                 \
                if([msgLength uInt32Value] > 0) {                                         \
                  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]]; \
                  [socket readNBytes:[msgLength uInt32Value] intoBuffer:message];         \
                }                                                                         \
          })
/*
 * Some random stuff needing a better description
 */
#   define EMPTY_MSG_SIZE               1
/*
 * Message Codes
 */
#   define MC_ERROR_RESPONSE            0
#   define MC_PING_REQUEST              1
#   define MC_PING_RESPONSE             2
#   define MC_GET_CLIENT_ID_REQUEST     3
#   define MC_GET_CLIENT_ID_RESPONSE    4
#   define MC_SET_CLIENT_ID_REQUEST     5
#   define MC_SET_CLIENT_ID_RESPONSE    6
#   define MC_GET_SERVER_INFO_REQUEST   7
#   define MC_GET_SERVER_INFO_RESPONSE  8
#   define MC_GET_REQUEST               9
#   define MC_GET_RESPONSE              10
#   define MC_PUT_REQUEST               11
#   define MC_PUT_RESPONSE              12
#   define MC_DEL_REQUEST               13
#   define MC_DEL_RESPONSE              14
#   define MC_LIST_BUCKETS_REQUEST      15
#   define MC_LIST_BUCKETS_RESPONSE     16
#   define MC_LIST_KEYS_REQUEST         17
#   define MC_LIST_KEYS_RESPONSE        18
#   define MC_GET_BUCKET_REQUEST        19
#   define MC_GET_BUCKET_RESPONSE       20
#   define MC_SET_BUCKET_REQUEST        21
#   define MC_SET_BUCKET_RESPONSE       22
#   define MC_MAP_REDUCE_REQUEST        23
#   define MC_MAP_REDUCE_RESPONSE       24
#endif

