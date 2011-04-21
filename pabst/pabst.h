/*
 *  pabst.h
 *  pabst
 *
 *  Created by Scott Gonyea on 4/20/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef pabst_
# define pabst_

# include <stdio.h>
# include <string.h>
# include <stdint.h>
# include <stdlib.h>

# import "riakclient.pb.h"
# import "message_codes.h"

//using namespace std;
//using google::sparse_hash_set;
//using ext::hash;
//
//struct eqstr {
//  bool operator()(const char* s1, const char* s2) const {
//    return (s1 == s2) || (s1 && s2 && strcmp(s1, s2) == 0);
//  }
//};
//
//typedef sparse_hash_set<const char*, __gnu_cxx::hash<const char*>, eqstr> strhash;
//
typedef struct {
  char *bucket;
  char *key;
  char *tag;
} _links;

typedef struct {
  char *key;
  char *value;
} _umeta;

typedef struct {
  _links    **links;
  uint32_t    links_c;
  _umeta    **umeta;
  uint32_t    umeta_c;
  
  
} _content;

typedef struct {
  uint32_t  n_val;
  bool      is_mult;
} _bucket_props;

_content       *unpackContent(RpbContent);
void            packContent(RpbContent *, _content *);

uint32_t        unpackLinks(_links **, RpbContent);
void            packLinks(_links **, RpbContent);

uint32_t        unpackUserMeta(_umeta **, RpbContent);
void            packUserMeta(_umeta **, RpbContent);

char           *buildEmptyRequest(uint8_t request_code);
char           *buildRequest(google::protobuf::Message *, uint8_t);

uint8_t         fetchReturnCode(char *);
uint32_t        fetchMessageLength(char *);

void            setMessageCode(char *, uint8_t);
void            setMessageLength(char *, uint32_t);

char           *req_ping(char *req_msg);
bool            rsp_ping(char *rsp_msg);

char           *req_getClientId(char *req_msg);
char           *rsp_getClientId(char *rsp_msg);

char           *req_setClientId(char *);
char           *req_setClientId(char *, size_t);
char           *rsq_setClientId(char *);

char           *req_getServerInfo();

char           *req_getKey(char *, char *, uint32_t);


char           *req_putKey(char *key, char *bucket, char *v_clock, _content *content, uint32_t quorum, uint32_t commit, bool return_body);


void            req_deleteKey(char *req_msg, char *key, char *bucket, uint32_t replicas);

char           *req_listBucketsRequest();
uint32_t        rsp_listBucketsRequest(char *rsp_msg, char **bucket_list);

void            req_listKeysInBucket(char *req_msg, char *bucket);
uint32_t        rsp_listKeysInBucket(char *rsp_msg, char **key_list, bool *is_done);

void            req_getBucket(char *req_msg, char *bucket);
_bucket_props  *rsp_getBucket(char *req_msg);

void            req_setBucket(char *req_msg, char *bucket, _bucket_props *props);
_bucket_props  *rsp_setBucket(char *rsp_msg);

void            req_mapReduceRequest(char *req_msg, char *request, char *content_type);
uint32_t        rsp_mapReduceRequest(char *rsp_msg, char *response, bool *is_done);

#endif
