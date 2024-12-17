# parse the group hash and return strings for group entries for
#  the snmpd.conf file
#  @see The SIMP user guide HOW TO: Configure SNMPD describes the hashes in
#    detail.
Puppet::Functions.create_function(:'simp_snmpd::grouplist') do
  # @param group_hash
  #    The list of groups to create.
  # @param defaultmodel
  #    The default Security model to use if that entry is not defined in the hash entry
  #
  # @return
  #   An array of strings that define groups for use for access in snmpd.conf files.
  dispatch :createlist do
    param 'Hash', :group_hash
    param 'String', :defaultmodel
  end

  def createlist(group_hash, defaultmodel)
    grouplist = []
    group_hash.each do |name, values|
      grouppref = name.to_s
      next unless !values.nil? && !values.empty?
      if values.key?('model')
        unless ['v1', 'v2c', 'usm', 'tsm', 'ksm'].include? values['model']
          raise("simp_snmpd: Badly formed group for key #{name}. model is #{values['model']} but must be one of 'v1','v2c','usm','tsm','ksm'")
        end
        model = values['model']

      else
        model = defaultmodel
      end
      raise("simp_snmpd: Badly formed group for key #{name}. It must include a value for secname") unless values.key?('secname') && !values['secname'].empty?
      if values['secname'].is_a?(Array)
        values['secname'].each do |user|
          grouplist.push("#{grouppref} #{model} #{user}")
        end
      else
        grouplist.push("#{grouppref} #{model} #{values['secname']}")
      end
    end
    grouplist
  end
end
