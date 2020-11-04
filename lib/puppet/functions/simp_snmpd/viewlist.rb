# parse the view hash and return strings that for view entries for
#  the snmpd.conf file
#  @see The SIMP user guide HOW TO: Configure SNMPD describes the hashes in
#    detail.

Puppet::Functions.create_function(:'simp_snmpd::viewlist') do

  # @param view_hash
  #    The list of views to create.
  #
  # @return
  #   An array of strings that define VACM view lines for use in snmpd.conf files.
  dispatch :createlist do
    param 'Hash', :view_hash
  end

  def createlist(view_hash)
    viewlist = []
    view_hash.each { | name, values|
       viewpref = "#{name}"
       if ! values.nil? and ! values.empty? then
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
