Puppet::Functions.create_function(:'simp_snmpd::grouplist') do
  dispatch :createlist do
    param 'Hash', :group_hash
    param 'String', :defaultmodel
  end

  def createlist(group_hash,defaultmodel)
    grouplist = []
    group_hash.each { | name, values|
      grouppref = "group #{name}"
      model = defaultmodel
      if values.length > 0 then
        if ['v1','v2c','usm','tsm','ksm'].include? values['model'] then
            model = values['model']
        end
        if values.has_key?('secname') and values['secname'].length > 0 then
           values['secname'].each { |user| 
              grouplist.push("#{grouppref} #{model} #{user}")
           }
        else
          grouplist.push("# badly formed group #{name} could not create configuraton item")
        end
     end
    }
    grouplist
  end
end
