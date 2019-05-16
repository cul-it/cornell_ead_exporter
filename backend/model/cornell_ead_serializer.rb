require 'nokogiri'
require 'securerandom'
require 'cgi'

class EADSerializer < ASpaceExport::Serializer
serializer_for :ead


def sanitize_mixed_content(content, context, fragments, allow_p = false  )
	#    return "" if content.nil?
	
		# remove smart quotes from text
		content = remove_smart_quotes(content)
	
		# br's should be self closing
		content = content.gsub("<br>", "<br/>").gsub("</br>", '')
		# lets break the text, if it has linebreaks but no p tags.
	
		if allow_p
		  content = handle_linebreaks(content)
		else
		  escape_content(content)
		end
	
		begin
		  if ASpaceExport::Utils.has_html?(content)
			context.text (fragments << content )
		  else
			context.text content.gsub("&amp;", "&") #thanks, Nokogiri
		  end
		rescue
		  context.cdata content
		end
	end
	
	def serialize_origination(data,xml,fragments)
		unless data.creators_and_sources.nil?
			data.creators_and_sources.each do |link|
			  agent = link['_resolved']
			  published = agent['publish'] === true
	  
			  next if (!published && !@include_unpublished) || agent['display_name']['sort_name'] == "no primary creator"
	  
			  link['role'] == 'creator' ? role = link['role'].capitalize : role = link['role']
			  relator = link['relator']
			  sort_name = agent['display_name']['sort_name']
			  rules = agent['display_name']['rules']
			  source = agent['display_name']['source']
			  authfilenumber = agent['display_name']['authority_id']
			  node_name = case agent['agent_type']
						  when 'agent_person'; 'persname'
						  when 'agent_family'; 'famname'
						  when 'agent_corporate_entity'; 'corpname'
						  end
	  
			  origination_attrs = {:label => role}
			  origination_attrs[:audience] = 'internal' unless published
			  xml.origination(origination_attrs) {
			   atts = {:role => relator, :source => source, :rules => rules, :authfilenumber => authfilenumber}
			   atts.reject! {|k, v| v.nil?}
	  
				xml.send(node_name, atts) {
				  sanitize_mixed_content(sort_name, xml, fragments )
				}
			  }
			end
	  end
end
end