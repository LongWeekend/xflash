#### JMDICT PARSER #####
=begin
  # -----------------------------------------------------------------------------------------
   DO NOT DELETE!
  # -----------------------------------------------------------------------------------------
  HEADWORD ELEMENTS
  <!ELEMENT k_ele (keb, ke_inf*, ke_pri*)>

  ENTRY > KELE > 
    KEB = a headword
    KEB + KE_PRI = a common headword (P) tag
    KEB + KE_INF = reading related tag (eg. ok, oK, ik, etc)

  * No KELE means the first reading is the headword!

  # -----------------------------------------------------------------------------------------
  READING ELEMENTS
  <!ELEMENT r_ele (reb, re_nokanji?, re_restr*, re_inf*, reb, re_nokanji?, re_restr*, re_inf*, re_pri**)>

  ENTRY > RELE >
    REB = a reading
    REB + RE_PRI = a common reading (P) tag (RE_PRI.value is name of its common word collection)
    REB + RE_NOKANJI = (ukana)
    REB + RE_INF = reading related tag (eg. ok, oK, ik, etc)
    REB + RE_RESTR.value = KELE this reading applies to

  * Requires at least one RELE > REB instance

  # -----------------------------------------------------------------------------------------
  MEANING/SENSE ELEMENTS <!ELEMENT sense (stagk*, stagr*, pos*, xref*, ant*, field*, misc*, s_inf*, lsource*, dial*, gloss*, example*)>

  ENTRY > SENSE
    + stagk.value = Contains HW-STRING-AS-KEY (current gloss applies to indicated HW only) (INTERNAL REF)
    + stagr.value = Contains READING-STRING-AS-KEY (current gloss applies to indicated READING only) (INTERNAL REF)
    + POS = part of speech (ALSO TAG TYPE)
    + XREF = cross reference by HW-STRING-AS-KEY or READING-STRING-AS-KEY (ANNOTATION)
    + ANT = antonym (ANNOTATION)
    + FIELD = field of use tag (ALSO TAG TYPE)
    + MISC = other info tag (ALSO TAG TYPE)
    + S_INF = additional usage info (ANNOTATION)
    + LSROUCE = language of origin e.g. <lsource xml:lang="kor"/> or <lsource xml:lang="ger">Abend</lsource> (ANNOTATION)
    + DIAL = japanese dialect (TAG INSTANCE ONLY)
    + GLOSS = the gloss / GLOSS['xml:lang']
    _ EXAMPLE = examples of usages (**Not found in JMDict)

  ENTRY > ENT_SEQ = JMDict ID number
  ENTRY > INFO > AUDIT = last update information
=end

class JMDictParser < Parser
  
  def initialize(file_name)
    super(file_name)
    @source_data_object = @source_xml.css('entry')
  end

  def run(include_non_english=false)
    entries = []

    tickcount("Iterating JMDict Records") do

      # Call 'super' method to process loop for us
      super do |entry, entry_no, cache_data|
        headwords = []
        readings = []
        meanings = []
        pos = []
        common_flag = false

        entry.css('k_ele').each do |k|
          keb = k.css('keb').text
          kinf = k.css('k_inf').collect {|t| t.text}
          kpre_arr = k.css('ke_pri').collect {|t| t.text}
          kpre = (kpre_arr.size > 0 ? "common" : nil)
          headwords <<  self.class.get_headword_hash(keb, Parser.combine_and_uniq_arrays(kinf,kpre), kpre_arr)
          common_flag = true if kpre_arr.size > 0
        end

        entry.css('r_ele').each do |r|
          reb = r.css('reb').text
          restr = r.css('re_restr').collect{|t| t.text}
          rinf = r.css('re_inf').collect{|t| t.text}
          rpre_arr = r.css('re_pri').collect {|t| t.text}
          rpre = (rpre_arr.size > 0 ? "common" : nil)
          nokanji = (r.css('re_nokanji').size > 0 ? "nokanji" : nil)
          readings <<  self.class.get_reading_hash(reb, Importer.xfrm_to_romaji(reb), Parser.combine_and_uniq_arrays(rinf, rpre, nokanji), restr, rpre_arr)
          common_flag = true if rpre_arr.size > 0
        end

        # Default headword to first reading
        if headwords.size < 1
          headwords << self.class.get_headword_hash(readings.first[:string])
        end

        entry.css('sense').each do |s|

          # Tmp storage hash for parts of a meaning (join with '/')
          glosses = {}
          glosses[:eng] = []
          meaning =  self.class.get_meaning_hash()

          s.css("pos,xref,ant,misc,field,s_inf,lsource,dial,stagr,stagk").each do |tag|
            if tag.name == "pos"
              # Get entity ref contents of tag
              pos << tag.children.first.children.first.name
            elsif ["misc", "field"].index(tag.name)
              # Get entity ref contents of tag
              meaning[:cat] << tag.children.first.children.first.name
            elsif  ["ant", "xref", "s_inf", "stagr", "stagk"].index(tag.name)
              meaning[:references] << { :type => tag.name, :target => tag.text }
            elsif  ["lsource"].index(tag.name)
              if tag.attributes['ls_wasei']
                meaning[:cat] << { :language => "ls_wasei", :word => tag.text }
              else
                meaning[:cat] << { :language => tag.attributes['lang'].text, :word => tag.text }
              end
            end

          end
        
          s.css('gloss').each do |g|
            if g.attributes["lang"]
              if include_non_english
                # non english
                lang_sym = g.attributes["lang"].text.to_sym
                glosses[lang_sym] = [] if !glosses[lang_sym]
                glosses[lang_sym] << g.text
              end
            else
              # english
              ##prt g.text
              glosses[:eng] << g.text
            end
          end

          meaning[:sense] = glosses[:eng].join("/")
          if include_non_english
            meaning[:non_english_meanings] = {}
            glosses.keys.each do |lang|
              if lang.to_s != "eng"
                meaning[:non_english_meanings][lang] = glosses[lang].join("/")
              end
            end
          end
          meanings << meaning

        end

        # add all the current entry data to the cache
        entries <<  self.class.get_entry_hash(meanings, headwords, readings, [entry.css('ent_seq').text], common_flag, Parser.combine_and_uniq_arrays(pos), [], [])
      end
    end
    return entries
  end

end