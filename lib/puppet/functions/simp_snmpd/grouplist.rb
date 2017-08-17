Puppet::Functions.create_function(:'simp_snmpd::grouplist') do
  dispatch :createlist do
    param 'Hash', :group_hash
    param 'String', :defaultmodel
  end

  def createlist(group_hash,defaultmodel)
    grouplist = []
    group_hash.each { | name, values|
      grouppref = "group #{name}"
      if values.length > 0 then
        if values.has_key?('model') then
          if ['v1','v2c','usm','tsm','ksm'].include? values['model'] then
            model = values['model']
          else
            fail("simp_snmpd: Badly formed group for key #{name}. model is #{values['model']} but must be one of 'v1','v2c','usm','tsm','ksm'")
          end
        else
          model = defaultmodel
        end
        if values.has_key?('secname') and values['secname'].length > 0 then
          if values['secname'].is_a?(Array) then
           values['secname'].each { |user|
              grouplist.push("#{grouppref} #{model} #{user}")
           }
          else
              grouplist.push("#{grouppref} #{model} #{values['secname']}")
          end
        else
          fail("simp_snmpd: Badly formed group for key #{name}. It must include a valuse for secname")
        end
     end
    }
    grouplist
  end
end
