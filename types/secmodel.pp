#type Simp_snmpd::Secmodel = Enum['usm','v1','v2c','tsm','ksm']
# Right now usm is the only type suppoerted by this module.
# If you want to use another type, use the puppet/snmp module directly
type Simp_snmpd::Secmodel = Enum['usm']
