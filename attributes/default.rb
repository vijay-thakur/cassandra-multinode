default[:cassandra] = {
  :nodeip => false,
  :logdir => '/var/log/cassandra',
  :libdir => '/var/lib/cassandra',
  :user => 'cassandra',
  :mountdevice => '/dev/xvdh',
  :conf_dir => '/etc/cassandra',
  :conf => {
    :cluster_name => 'jagat_cassandra_cluster',
    :rpc_address => '0.0.0.0',
    :node1 => '10.2.5.170',
    :node2 => '10.2.5.171',
    :node3 => '10.2.5.170',
    :nodeip => '10.2.5.170'
  },
  :src_deps => %w{gcc libev4 libev-dev python-dev dsc30 cassandra-tools}
  }
