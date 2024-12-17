# parse the access hash and return strings that for access entries for
#  the snmpd.conf file
#  @see The SIMP user guide HOW TO: Configure SNMPD describes the hashes in
#    detail.
Puppet::Functions.create_function(:'simp_snmpd::accesslist') do
  # @param access_hash
  #    The list of accesses to create.
  # @param defaultmodel
  #    The default Security model to use if that entry is not defined in the hash entry
  # @param defaultlevel
  #    The default Security level to use if that entry is not defined in the hash entry
  #
  # @return
  #   An array of strings that define VACM access lines for use in snmpd.conf files.
  dispatch :createlist do
    param 'Hash', :access_hash
    param 'String', :defaultmodel
    param 'String', :defaultlevel
  end

  def createlist(access_hash, defaultmodel, defaultlevel)
    # access GROUP CONTEXT {any|v1|v2c|usm|tsm|ksm} LEVEL PREFX READ WRITE NOTIFY']
    accesslist = []
    access_hash.each do |name, values|
      next unless !values.nil? && !values.empty?
      raise("simp_snmpd: access_hash definition #{name} is missing either view or groups key.") unless values.key?('view') && values.key?('groups')
      model = defaultmodel
      level = defaultlevel
      view = { 'read' => 'none', 'write' => 'none', 'notify' => 'none' }
      prefx = 'exact'
      context = '""'
      values.each do |key, setting|
        case key
        when 'model'
          raise("simp_snmpd: access_hash - model is:  #{setting} model must be one of 'any','v1','v2c','usm','tsm','ksm'") unless ['any', 'v1', 'v2c', 'usm', 'tsm', 'ksm'].include? setting
          model = setting

        when 'view'
          raise('simp_snmpd: access_hash - expects a hash for view with one or more of read, write, notify keys.') unless setting.is_a?(Hash)
          setting.each do |type, value|
            case type
            when %r{^(read|write|notify)$}
              view[type] = value
            else
              raise("simp_snmpd: access_hash - invalid key #{type} in view must be read, write, or notify")
            end
          end
          view = "#{view['read']} #{view['write']} #{view['notify']}"

        when 'level'
          raise("simp_snmpd: access_hash - level is:  #{setting} level must be one of 'auth','priv','noauth'") unless ['auth', 'priv', 'noauth'].include? setting
          level = setting

        when 'context'
          context = setting
        when %r{^(prefx|prefix)$}
          raise("simp_snmpd: access_hash - prefix is:  #{setting} level must be one of 'exact' or 'prefix'") unless ['exact', 'prefix'].include? setting
          prefx = setting

        when 'groups'
          if values['groups'].is_a?(Array)
            values['groups']
          else
            [ values['groups'] ]
          end
        else
          raise("simp_snmpd: access_hash #{name} has invalid key #{key}")
        end
      end
      groups = if values['groups'].is_a?(Array)
                 values['groups']
               else
                 [ values['groups'] ]
               end
      groups.each do |group|
        accesslist.push("#{group} #{context} #{model} #{level} #{prefx} #{view}")
      end
    end
    accesslist
  end
end
