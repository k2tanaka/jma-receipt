#!/usr/bin/ruby
# coding : utf-8
Encoding.default_external = "euc-jp" unless RUBY_VERSION == "1.8.7"

require "csv"
require "iconv"
require "monthly/receden_common"

$KCODE = "UTF-8"

class Receden < Receden_common

  attr_reader :ir,:go,:receipt,:info

  def initialize(receden_file)

    @ir=Array.new
    @go=Array.new
    @sai=Array.new
    @etc=Array.new
    @receipt=Array.new
    @info=Recinfo.new

    block =Array.new
    j=0
    k=0
    receline=0
    open(receden_file) {|f|
      f.each_with_index{|data,line|
        csv=Csvline.new
        csv.line=line + 1
        csv.rows=data.chomp.split(",",-1)
        case csv.rows[0]
        when "RE","HO","RO","KO","KH",
             "SY","SI","IY","TO","CO","NI","SJ",
             "1","2","3","4","8","11","12","13","14"
          if block[0] == nil
             block[0] = Array.new
             receline=0
          end
          if csv.rows[0] == "RE"
            if block[j].size > 0
               j += 1
               block[j] = Array.new
               receline=0
            end
          end
          receline += 1
          csv.receline = receline
          block[j] << csv
        else
          receline=0
          csv.receline = receline
          case csv.rows[0]
          when "IR"
            @ir << csv_to_hash(@info["IR"],csv)
          when "GO"
            @go << csv_to_hash(@info["GO"],csv)
          else
            @etc << csv_to_hash(@info["ETC"],csv)
          end
        end
      }
    }
    block.each{|recedata|
        @receipt << Recept.new(recedata,@info)
    }
  end
end

class Recept < Receden_common

  attr_reader :re,:ho,:ro,:ko,:kh,:sy,:tekiyo,:sj,:sai,:rows,:sbt,:tokki,:age

  def initialize(recedata,info)

    @re=Array.new
    @ho=Array.new
    @ro=Array.new
    @ko=Array.new
    @kh=Array.new
    @sy=Array.new
    @re=Array.new
    @sj=Array.new
    @sai=Array.new

    @tekiyo=Array.new

    @rows=Array.new
    @tokki=Array.new
    @sbt=Recesbt.new("")
    @age=nil

    block =Array.new

    i=0
    j=0
    recedata.each{|csv|

      @rows << csv

      case csv.rows[0]
      when "SI","IY","TO","CO","NI"
        if block[0] == nil
           block[0] = Array.new
        end
        if csv.rows[0] != "NI" && csv.rows[1].strip != ""
          if block[j].size > 0
             j += 1
             block[j] = Array.new
          end
        end
        block[j] << csv
      when "RE"
        @re << csv_to_hash(info["RE"],csv)
      when "HO"
        @ho << csv_to_hash(info["HO"],csv)
      when "RO"
        @ro << csv_to_hash(info["RO"],csv)
      when "KO"
        @ko << csv_to_hash(info["KO"],csv)
      when "KH"
        @ko << csv_to_hash(info["KH"],csv)
      when "SY"
        @sy << csv_to_hash(info["SY"],csv)
      when "SJ"
        if @sj[0] == nil
          @sj[0]=Array.new
        end
        if csv.rows[1].strip != ""
          if @sj[i].size >  0
            i += 1
            @sj[i]=Array.new
          end
        end
        @sj[i] << csv_to_hash(info["SJ"],csv)
      when "1","2","3","4","8","11","12","13","14"
        @sai << csv_to_hash(info["SAI"],csv)
      end
    }

    if @re.empty?
    else

      @sbt=Recesbt.new(@re[0]["RECESBT"].value)

      if @re[0]["TOKKI"].value =~ /^(|(  |[0-9]{2})+)$/
         @tokki=@re[0]["TOKKI"].value.scan(/[0-9]{2}/)
      end
      @age = ((re[0]["SRYYM"].wtos.to_i - re[0]["BIRTHDAY"].wtos.to_i) / 10000).to_i

    end

    block.each{|zaidata|
        @tekiyo << Tekiyo.new(zaidata,info)
    }
  end


end

class Tekiyo < Receden_common

  attr_reader :zai,:srykbn

  def initialize(zaidata,info)

    @zai=Array.new
    @srykbn=""

    zaidata.each {|csv|
      case csv.rows[0]
      when "SI"
          @zai << csv_to_hash(info["SI"],csv)
      when "IY"
          @zai << csv_to_hash(info["IY"],csv)
      when "TO"
          @zai << csv_to_hash(info["TO"],csv)
      when "CO"
          @zai << csv_to_hash(info["CO"],csv)
      when "NI"
          @zai << csv_to_hash(info["NI"],csv)
      end
    }

    if @zai.first.hash.key?("SRYKBN")
      @srykbn = @zai.first["SRYKBN"].value
    end

  end
end
