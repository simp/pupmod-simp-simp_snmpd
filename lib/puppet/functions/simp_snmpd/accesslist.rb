Puppet::Functions.create_function(:'simp_snmpd::accesslist') do
  dispatch :createlist do
    param 'Hash', :access_hash
    param 'String', :defaultmodel
    param 'String', :defaultlevel
  end

  def createlist(access_hash,defaultmodel,defaultlevel)
    accesslist = ['#access GROUP CONTEXT {any|v1|v2c|usm|tsm|ksm} LEVEL PREFX READ WRITE NOTIFY']
    access_hash.each { | name, values|
      accesspref = "access"
      if values.length > 0 then
        if  values.has_key?('view') and values.has_key?('groups')  then 
          model = defaultmodel
          level = defaultlevel
          view = 'none none none'
          prefx = 'exact'
          context = '""'
          values.each { |key, setting|
            case key
            when 'model'
              if ['any','v1','v2c','usm','tsm','ksm'].include? setting then
                model = setting
              end
            when 'view'
              vread = setting['read'] || 'none'
              vwrite = setting['write'] || 'none'
              vnotify = setting['notify'] || 'none'
              view = "#{vread} #{vwrite} #{vnotify}"
            when 'level'
              if ['auth','priv','noauth'].include setting then
                level = setting
              end
            when 'context'
               context = "#{context}"
            when 'prefx'
              if ['exact','prefix'].include? setting then
                  prefix = setting
              end
            end
          }
          values['groups'].each { |group|
            accesslist.push("#{accesspref} #{group} #{context} #{model} #{level} #{prefx} #{view}")
          }
        else
          accesslist.push("#access definition #{name} is missing either view, type or groups. Can not configure it")
        end
     end
    }
    accesslist
  end
end
