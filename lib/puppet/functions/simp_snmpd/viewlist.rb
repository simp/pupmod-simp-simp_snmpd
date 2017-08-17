Puppet::Functions.create_function(:'simp_snmpd::viewlist') do
  dispatch :createlist do
    param 'Hash', :view_hash
  end

  def createlist(view_hash)
    viewlist = []
    view_hash.each { | name, values|
       viewpref = "view #{name}"
       if values.length > 0 then
         values.each { |type, oids|
           case "#{type}"
           when /^(included|excluded)$/
               if oids.is_a?(Array)
                 oids.each { |elements|
                   viewlist.push("#{viewpref} #{type} #{elements}")
                 }
               else
                 elements = oids
                 viewlist.push("#{viewpref} #{type} #{elements}")
               end
           else
             fail("simp_snmpd: Badly formed view_hash entry #{name}.  Type key must be included or excluded and was #{type}.")
           end
         }
       end
    }
    viewlist
  end
end
