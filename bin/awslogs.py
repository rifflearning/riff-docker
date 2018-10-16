#!/usr/bin/env python3

# awslogs.py
# author: Michael Jay Lippert mike@rifflearning.com
# Command line tool for viewing the logs from AWS Cloudwatch for a riff swarm

import sys
import boto3
import json
import re
from datetime import datetime

client = boto3.client('logs')


# TODO get this from the commandline
swarmName = 'staging'

#response = client.describe_log_groups(#logGroupNamePrefix='string',
#                                      #nextToken='string',
#                                      limit=10)

#print([lg['logGroupName'] for lg in response['logGroups']])

# It looks like the docker swarm stack that we deploy has a standard
# name for the log group, ie stack name + '-lg'
# We are using a standard stack name of swarm env name (ie staging, beta, prod...)
# + 'swarm'
logGroupName = swarmName + 'swarm-lg'

# TODO find the latest log stream with the right prefix
#logStreamPrefix = 'riff-stack_riff-rtc'
#response = client.describe_log_streams(logGroupName=logGroupName,
#                                       #logStreamNamePrefix='string',
#                                       #orderBy='LogStreamName'|'LastEventTime',
#                                       orderBy='LastEventTime',
#                                       descending=True,
#                                       #nextToken='string',
#                                       limit=10)
#
#print(json.dumps([ls['logStreamName'] for ls in response['logStreams']], sort_keys=True, indent=2))
#sys.exit()

logStreamName = 'riff-stack_riff-rtc.1.d69t3hn9yk66kyb8rava9fp7p-49da7432e96e'
#                riff-stack_riff-rtc.1.pzvtjiaqyqbh1dvbbsj31kcri-f50f0d1dc7d0

def rmTermCtrlSeq(s):
    """
    Remove Terminal CSI sequences from s

    see https://en.wikipedia.org/wiki/ANSI_escape_code
    """
    tcsReStr = '\x1b\\[[\x30-\x3F]*[\x20-\x2F]*[\x40-\x7E]'
    tcsRe =  re.compile(tcsReStr)
    return re.sub(tcsRe, '', s)

response = client.get_log_events(logGroupName=logGroupName,
                                 logStreamName=logStreamName,
                                 #startTime=123,
                                 #endTime=123,
                                 #nextToken='string',
                                 limit=15,
                                 startFromHead=False)

#print(json.dumps(response, sort_keys=True, indent=2))

events = []
for event in response['events']:
    print(event)
    newEvent = {}
    for k,v in event.items():
        if k == 'message':
            v = json.loads(v) if v[0] == '{' else rmTermCtrlSeq(v)
        elif k == 'timestamp':
            v = datetime.fromtimestamp(v/1000)

        newEvent[k] = v

    events.append(newEvent)

#print(events)
#sys.exit()

# extract the messages from the events
rawMsgs = [event['message'] for event in response['events']]
msgs = [json.loads(msg) if msg[0] == '{' else rmTermCtrlSeq(msg) for msg in rawMsgs]
#print(json.dumps(msgs, sort_keys=True, indent=2))

bunyanMsgs = [m for m in msgs if isinstance(m, dict)]
#filteredMsgs = [m for m in msgs if isinstance(m, dict) if m['route_handler'] == 'spaIndex']
filteredMsgs = [m for m in bunyanMsgs if m['route_handler'] == 'spaIndex']
print(json.dumps(filteredMsgs, sort_keys=True, indent=2))
counts = { 'foundCnt': len(filteredMsgs), 'bunyanCnt': len(bunyanMsgs), 'totalCnt': len(msgs) }
print('the number of messages found is: {foundCnt} out of {bunyanCnt} bunyan msgs out of {totalCnt} total msgs'.format(**counts))

sys.exit()

