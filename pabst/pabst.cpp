/*
 *  pabst.cp
 *  pabst
 *
 *  Created by Scott Gonyea on 4/20/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "pabst.h"

char *buildRequest(google::protobuf::Message *pb_msg, uint8_t msg_code) {
  uint32_t  msg_len = pb_msg->ByteSize();

  char     *req_msg = (char *)malloc(msg_len + MSG_PAD_SIZE);

  setMessageCode(req_msg, msg_code);
  setMessageLength(req_msg, msg_len + MC_SIZE);

  pb_msg->SerializeToArray(req_msg + MSG_PAD_SIZE, msg_len);

  return(req_msg);
}

char  *buildEmptyRequest(uint8_t msg_code) {
  char *req_msg = (char *)malloc(MSG_PAD_SIZE);

  setMessageCode(req_msg, msg_code);
  setMessageLength(req_msg, EMPTY_MSG_SIZE);

  return(req_msg);
}

uint8_t fetchReturnCode(char *rsp_msg) {
  return (uint8_t) *(rsp_msg + MC_OFFSET);
}

uint32_t fetchMessageLength(char *rsp_msg) {
  return ntohl((uint32_t) *(rsp_msg + ML_OFFSET));
}

void setMessageCode(char *req_msg, uint8_t msg_code) {
  memcpy(req_msg + MC_OFFSET, (char *)msg_code, MSG_CODE_SIZE);
}

void setMessageLength(char *req_msg, uint32_t msg_length) {
  memcpy(req_msg + ML_OFFSET, (void *)htonl(msg_length),  MSG_LENGTH_SIZE);
}




/** Ping
 **
 *  Request
 *    Send Message Code, Only
 */
char  *req_ping() {
  return(buildEmptyRequest(MC_PING_REQUEST));
}

/*  Response
 *    riak sends Message Code, Only, as confirmation
 */
bool  rsp_ping(char *rsp_msg) {
  if(fetchReturnCode(rsp_msg) == MC_PING_RESPONSE) {
    return true;
  }

  return false;
}




/** Get Client ID
 **
 *  Request
 *    Send Message Code, Only
 */
char  *req_getClientId() {
  return(buildEmptyRequest(MC_GET_CLIENT_ID_REQUEST));
}

/*  Response
 *    riak sends a 4-byte value
 */
char  *rsp_getClientId(char *rsp_msg) {
  if(fetchReturnCode(rsp_msg) != MC_GET_CLIENT_ID_RESPONSE) {
    return(NULL);
  }

  uint32_t  msg_len   = fetchMessageLength(rsp_msg);
  char     *response  = (char *)malloc(msg_len + MSG_NIL_SIZE);

  memcpy(response, rsp_msg + MSG_PAD_SIZE, msg_len);
  response[msg_len] = NULL;

  return(response);
}




/** Set Client ID
/**
 *  Request
 *    @todo Describe the request
 */
char  *req_setClientId(char *client_id) {
  if(client_id == NULL) {
    return(NULL);
  }

  return req_setClientId(client_id, strlen(client_id));
}

/*  Request
 *    @todo Describe the request
 */
char  *req_setClientId(char *client_id, size_t client_id_len) {
  if(client_id == NULL) {
    return(NULL);
  }
  RpbSetClientIdReq pb_msg;

  pb_msg.set_client_id((void *)client_id, client_id_len);

  return buildRequest(&pb_msg, MC_SET_CLIENT_ID_REQUEST);
}


/*  Request
 *    @todo Describe the response
 */
bool  rsp_setClientId(char *rsp_msg) {
  if(fetchReturnCode(rsp_msg) == MC_SET_CLIENT_ID_RESPONSE) {
    return true;
  }

  return false;
}




char  *req_getServerInfo() {
  return(buildEmptyRequest(MC_GET_SERVER_INFO_REQUEST));
}




/** Get Key from Bucket Request
 **
 *  Request
 *    Send the name of the bucket (1), the key (2), and the quorum (3)
 *
 *  Response
 *    riak sends two values: the bucket+key's vclock (1) and content(s) on the key (2)
 */
char  *req_getKey(char *key, char *bucket, uint32_t quorum) {
  RpbGetReq pb_msg;

  pb_msg.set_bucket(bucket);
  pb_msg.set_key(key);

  if(quorum) {
    pb_msg.set_r(quorum);
  }

  return buildRequest(&pb_msg, MC_GET_REQUEST);
}


/*  Response
 *    riak sends two values: the bucket+key's vclock (1) and content(s) on the key (2)
 */




/** Put Key in Bucket Request
 **
 *  Request
 *    Send the name of the bucket (1), the key (2), the key's content (3), the quorum (4), and the commits-before-ack (5)
 *
 *  Response
 *    riak sends either the message code or (optionally) two values: the bucket+key's vclock (1) and content(s) on the key (2)
 */
char  *putKey(char *key, char *bucket, char *v_clock, _content *content, uint32_t quorum, uint32_t commit, bool return_body) {
  RpbPutReq pb_msg;

  pb_msg.set_bucket(bucket);
  pb_msg.set_key(key);

  if(commit)  pb_msg.set_dw(commit);
  if(quorum)  pb_msg.set_w(quorum);
  if(v_clock) pb_msg.set_vclock(v_clock);

  packContent(pb_msg.mutable_content(), content);

  return buildRequest(&pb_msg, MC_PUT_REQUEST);
}




/** Delete Key from Bucket Request
 **
 *  Request
 *    Send the name of the bucket (1), the key name (2), and the num replicas that should confirm deletion (3)
 *
 *  Response
 *    riak sends Message Code, Only, as confirmation
 */
char  *deleteKey(char *key, char *bucket, uint32_t replicas) {
  RpbDelReq pb_msg;

  pb_msg.set_bucket(bucket);
  pb_msg.set_key(key);

  if(replicas)  pb_msg.set_rw(replicas);

  return buildRequest(&pb_msg, MC_DEL_REQUEST);
}




char  *req_listBucketsRequest() {
  return(buildEmptyRequest(MC_LIST_BUCKETS_REQUEST));
}




uint32_t  rsp_listBucketsRequest(char *rsp_msg, char **bucket_list) {
  if(rsp_msg == NULL)
    return NULL;

  RpbListBucketsResp pb_msg;

  uint32_t msg_len    = fetchMessageLength(rsp_msg) - MC_SIZE;
  uint32_t bucket_cnt = pb_msg.buckets_size();
  uint32_t iter;

  pb_msg.ParseFromArray(rsp_msg + MSG_PAD_SIZE, msg_len);

  bucket_cnt  = pb_msg.buckets_size();
  bucket_list = (char **)malloc(bucket_cnt * sizeof(size_t));

  for(iter = 0; iter < bucket_cnt; iter++) {
    unsigned long name_len = pb_msg.buckets(iter).length();

    bucket_list[iter] = (char *)malloc(name_len);

    memcpy(bucket_list[iter], pb_msg.buckets(iter).c_str(), name_len);
  }

  return(bucket_cnt);
}

//uint32_t        req_listBucketsRequest();
//uint32_t        rsp_listBucketsRequest(char *rsp_msg, char **bucket_list);
//
//void            req_listKeysInBucket(char *req_msg, char *bucket);
//uint32_t        rsp_listKeysInBucket(char *rsp_msg, char **key_list, bool *is_done);
//
//void            req_getBucket(char *req_msg, char *bucket);
//_bucket_props  *rsp_getBucket(char *req_msg);
//
//void            req_setBucket(char *req_msg, char *bucket, _bucket_props *props);
//_bucket_props  *rsp_setBucket(char *rsp_msg);
//
//void            req_mapReduceRequest(char *req_msg, char *request, char *content_type);
//uint32_t        rsp_mapReduceRequest(char *rsp_msg, char *response, bool *is_done);
