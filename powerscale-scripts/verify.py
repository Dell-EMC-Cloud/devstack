from __future__ import print_function
from os import system
import sys
from pprint import pprint
import time
import urllib3

import isi_sdk_9_0_0
from isi_sdk_9_0_0.rest import ApiException

urllib3.disable_warnings()

clusters = {
    'slb': [
        {
            'idx': '1',
            'mgmt_ip': '172.19.33.5',
            'data_ip': '192.168.16.5'
        },
        {
            'idx': '2',
            'mgmt_ip': '172.19.33.6',
            'data_ip': '192.168.16.6'
        }
    ],
    'hps': [
        {
            'idx': '1',
            'mgmt_ip': '172.19.34.5',
            'data_ip': '192.168.32.5'
        },
        {
            'idx': '2',
            'mgmt_ip': '172.19.34.6',
            'data_ip': '192.168.32.6'
        }
    ]
}


def terminate(api_client):
    api_client.pool.close()
    api_client.pool.terminate()


for name, nodes in clusters.items():
    print('\n\nCluster {name}:'.format(name=name))
    for node in nodes:
        print('    Node {idx} in cluster {name}:'.format(idx=node['idx'], name=name))
        if node.get('mgmt_ip'):
            if system('        ping -c 1 {} > /dev/null'.format(node['mgmt_ip'])) == 0:
                print('        mgmt ip ({ip}) is up'.format(ip=node['mgmt_ip']))

                # configure cluster connection: basicAuth
                configuration = isi_sdk_9_0_0.Configuration()
                configuration.host = 'https://{}:8080'.format(node['mgmt_ip'])
                configuration.username = 'root'
                configuration.password = 'a'
                configuration.verify_ssl = False

                # create an instance of the API class
                api_client = isi_sdk_9_0_0.ApiClient(configuration)
                api_client.__class__.__del__ =  terminate
                api_instance = isi_sdk_9_0_0.ClusterApi(api_client)
                timeout = 8.14  # float | Request timeout (optional)

                try:
                    print('        Connecting to PAPI to fetch cluster identity for {name}...'.format(name=name))
                    api_response = api_instance.get_cluster_identity()
                    print('{}'.format(api_response))
                except ApiException as e:
                    print("Exception when calling ClusterApi->get_cluster_identity: %s\n" % e)
                except:
                    print('PAPI is not available')

                try:
                    print('        Connecting to PAPI to fetch cluster info for {name}...'.format(name=name))
                    api_response = api_instance.get_cluster_nodes(timeout=timeout)
                    print('        There are {} nodes in cluster'.format(api_response.total))
                except ApiException as e:
                    print("Exception when calling ClusterApi->get_cluster_nodes: %s\n" % e)
                except:
                    print('PAPI is not available')
            else:
                print('        mgmt ip ({ip}) is down'.format(ip=node['mgmt_ip']))

        if node.get('data_ip'):
            if system('ping -c 1 {} > /dev/null'.format(node['data_ip'])) == 0:
                print('        data ip ({ip}) is up'.format(ip=node['data_ip']))
            else:
                print('        data ip ({ip}) is down'.format(ip=node['data_ip']))
        print('')
