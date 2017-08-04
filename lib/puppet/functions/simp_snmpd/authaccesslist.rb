Puppet::Functions.create_function(:'simp_snmpd::authaccesslist') do
  dispatch :createlist do
    param 'Hash', :access_hash
    param 'String', :defaultmodel
    param 'String', :defaultlevel
  end

  def createlist(access_hash,defaultmodel,defaultlevel)
    accesslist = ['#authaccess TYPES [-s MODEL] GROUP VIEW [LEVEL [CONTEXT]]']
    access_hash.each { | name, values|
      accesspref = "authaccess"
      if values.length > 0 then
        if  values.has_key?('view') and values.has_key?('groups')  then
          model = "-s #{defaultmodel}"
          level = defaultlevel
          type = 'read'
          view = 'none'
          values.each { |key, setting|
            case key
            when 'model'
              if ['any','v1','v2c','usm','tsm','ksm'].include? setting then
                model = "-s #{setting}"
              end
            when 'view'
              view = setting
            when 'level'
              if values.has_key?('context')
               level = "#{setting} #{values['context']}"
              else
                level = setting
              end
            when 'type'
              if ['read,write','rw','RW'].include? setting then
                  type = 'read,write'
              end
            end
          }
          values['groups'].each { |group|
            accesslist.push("#{accesspref} #{type} #{model} #{group} #{view}")
          }
        else
          accesslist.push("#access definition #{name} is missing either view, type or groups. Can not configure it")
        end
     end
    }
    accesslist
  end
end
