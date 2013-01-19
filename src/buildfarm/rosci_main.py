from __future__ import print_function

import os

from optparse import OptionParser

from .jenkins_support import load_server_config_file, get_default_catkin_debs_config, JenkinsConfig_to_handle
from .rosci_creator import process_jobs, load_jobs_from_file

NAME='rosci'

def rosci_main():
    parser = OptionParser(usage="usage: %prog <jobs.yaml> <rosdistro-name>", prog=NAME)
    parser.add_option("--commit", dest="commit", action="store_true", help="Actually upload to Jenkins", default=False)
    options, args = parser.parse_args()
    if len(args) < 2:
        parser.error("please specify jobs.yaml file and ROS distribution name (e.g. fuerte)")

    jobs_yaml_path = args[0]
    if not os.path.isfile(jobs_yaml_path):
        parser.error("invalid jobs.yaml path: %s"%jobs_yaml_path)
    rosdistro_name = args[1]

    server_config = load_server_config_file(get_default_catkin_debs_config())
    jenkins_handle = JenkinsConfig_to_handle(server_config)
    jobs_data = load_jobs_from_file(jobs_yaml_path)

    process_jobs(jobs_data, jenkins_handle, rosdistro_name, not options.commit)
    
