type Simp_snmpd::Listeningaddr = Tuple[Simp_snmpd::Protocol, Variant[Simplib::IP::V4, Simplib::IP::V6::Bracketed, Simplib::Hostname, Stdlib::Unixpath], Optional[Variant[Simplib::Port,String]]]
