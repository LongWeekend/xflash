#
# Credits: nowake@fiercewinds.net
# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/39747
# 2008-04-28  Modified to keep track of # of changes
#
require 'singleton'

module SimpleDiff

  class DiffBuilder
    attr_reader( :original, :modification )
    attr_accessor( :traverse_processor )
    def initialize( original, modification )
      @traverse_processor = self
      @ori = original
      @mod = modification
      @lcs_path = find_lcs_path
      @added = 0
      @deleted = 0
      @keeping = 0
    end

    ############################################
    # トラバース処理（イベント駆動のdiff処理）
    def traverse
      traverse_path( @traverse_processor )
    end
    # 以下はオーバーライドして定義のこと
    def deleted( original_pos, modification_pos, token )
      # originalにのみ現れるtokenの処理
      @deleted = @deleted +1
    end
    def added( original_pos, modification_pos, token )
      # modificationにのみ現れるtokenの処理
      @added = @added +1
    end
    def keeping( original_pos, modification_pos, token )
      # 両方に現れるtokenの処理
      @keeping = @keeping +1
    end

    ############################################
    # 結果
    def original_base_diff
      obj = OriginalBaseResult::FactoryProcessor.new
      traverse_path( obj )
      obj.result
    end
    
    ############################################
    # Return amounts changed [#kept, # added, # deleted, original size,]
    def whats_changed?
      change_nos = [ @keeping, @added, @deleted, @ori.size ]
      return change_nos
    end

  private
    def traverse_path( processor )
      0.upto(@lcs_path[0].size-2) do | i |
        x = @lcs_path[0][i]; y = @lcs_path[1][i]
        mx = @lcs_path[0][i+1]; my = @lcs_path[1][i+1]
        while x < mx and y < my
          processor.keeping( x, y, @ori[x] )
          x += 1; y += 1
        end
        while x < mx
          processor.deleted( x, my, @ori[x] )
          x += 1
        end
        while y < my
          processor.added( mx, y, @mod[y] )
          y += 1
        end
      end
    end

    ############################################
    # O(NP) Algorithm
    def find_lcs_path
      if @ori.size < @mod.size then 
        find_lcs_np(@ori, @mod)
      else
        find_lcs_np(@mod, @ori).reverse
      end
    end
    def find_lcs_np( shorter, longer )
      fp = Array.new( longer.size + shorter.size + 2, -1 )
      delta = longer.size - shorter.size
      editgraph = Hash.new( -1 )
      0.upto( shorter.size ) do | p |
        (-p).upto(delta-1) do | k |
          fp[k] = snake(k,fp[k-1]+1,fp[k+1],longer,shorter,editgraph,fp )
        end
        (delta+p).downto(delta) do | k |
          fp[k] = snake(k,fp[k-1]+1,fp[k+1],longer,shorter,editgraph,fp )
        end
        return create_path(editgraph,shorter,longer) if fp[delta]==longer.size
      end
      raise 'O(NP) Diff Error'
    end

    def snake( k, fpa, fpb, longer, shorter, editgraph,fp )
      y = fpa > fpb ? fpa : fpb; x = y - k
      count = 0
      while x < shorter.size and y < longer.size and shorter[x]==longer[y]
        x += 1; y += 1; count += 1
      end
      editgraph[x + y*longer.size] = count
      return y
    end

    def create_path( editgraph, shorter, longer )
      x = shorter.size; y = longer.size
      shorter_pos = [x]; longer_pos = [y]
      while 0 < x and 0 < y
        raise 'Diff Error' if editgraph[x + y*longer.size] < 0
        s = editgraph[x + y*longer.size]
        x -= s; y -= s
        shorter_pos << x; longer_pos << y
        if 0 <= editgraph[x + (y-1)*longer.size]
          begin y -= 1 end while 0 < y and 0 <= editgraph[x+(y-1)*longer.size]
          shorter_pos << x; longer_pos << y
        end
        if 0 <= editgraph[x - 1 + y*longer.size]
          begin x -= 1 end while 0 < x and 0 <= editgraph[x-1+y*longer.size]
          shorter_pos << x; longer_pos << y
        end
      end
      if shorter_pos[-1] != 0 and longer_pos[-1] != 0
        shorter_pos << 0; longer_pos << 0
      end
      [shorter_pos.reverse, longer_pos.reverse]
    end

    #########################################################################
    # Diffの結果を保持するオブジェクト
    #   各要素の内容は次の通り
    #   基準は全てoriginal
    #   [操作する部分のoriginalに対する位置の先頭, 前の内容, 後の内容]
    class OriginalBaseResult
      class NoChange
        include Singleton
        def inspect; '*' end
      end
      class FactoryProcessor
        def initialize; @result = []; @index = 0 end
        def result; OriginalBaseResult.new( @result ) end
        def deleted(i, j, v)
          if @joint
            @result[-1][1] << v
          else
            @result << [@index, [v], []]
            @joint = true
          end
          @index += 1
        end
        def added(i, j, v)
          if @joint
            @result[-1][2] << v
          else
            @result << [@index, [], [v]]
            @joint = true
          end
        end
        def keeping(i, j, v)
          @index += 1
          @joint = false
        end
      end
      def initialize( result_array=[] )
        @data = independent( result_array )
      end
      def inspect; @data.inspect end
      def size; @data.size end
      def empty?; @data.empty? end
      def []( var ); @data[var] end

      def patch( original )
        result = []
        index = 0
        @data.each do | i |
          result.concat( original[index...i[0]] )
          result.concat( i[2] )
          index = i[0] + i[1].size
        end
        result.concat(original[index...original.size]) if index<original.size
        result
      end

      def reverse
        result = []
        gap = 0
        @data.each do | i |
          result << [i[0] + gap, [], []]
          i[1].each do | j | result[-1][2] << j end
          i[2].each do | j | result[-1][1] << j end
          gap += i[2].size - i[1].size
        end
        OriginalBaseResult.new( result )
      end

      def <<( addition ) #手抜き実装
        if @data.empty?
          @data = addition.data
        else
          o = Array.new( @data[-1][0]+@data[-1][1].size, NoChange.instance )
          @data.each do | i | o[i[0], i[1].size] = i[1] end
          t = self.patch( o )
          addition.data.each do | i | t[i[0], i[1].size] = i[1] end
          o = self.reverse.patch( t )
          t = addition.patch( t )
          @data = DiffBuilder.new( o, t ).original_base_diff.data
        end
        return self
      end

      def ignore( remove )
        return self if remove.empty? or @data.empty?
        result = []; t = []
        d = independent( @data ); r = independent( remove.data )
        until d.empty? or r.empty?
          if d[0][0] <= r[0][0]
            t.clear
            d[0][2].each do | i |
              if i == r[0][2][0] then r[0][2].shift else t << i end
            end
            if d[0][0] == r[0][0]
              while (not r[0][1].empty?) and (d[0][1][0] == r[0][1][0])
                d[0][1].shift; r[0][1].shift; d[0][0] += 1; r[0][0] += 1
              end
            end
            result << [d[0][0], d[0][1][0...(r[0][0]-d[0][0])], t.clone]
            result.pop if result[-1][1].empty? and result[-1][2].empty? 
          end
          if d[0][0] < r[0][0] + r[0][1].size
            d[0][1] = d[0][1][(r[0][0]+r[0][1].size-d[0][0])...d[0][1].size]
            if (not d[0][1]) or d[0][1].empty?
              d.shift
              next
            else
              d[0][2].clear
              d[0][0] = r[0][0] + r[0][1].size
            end
          elsif d[0][0] == r[0][0] and d[0][1].empty? and r[0][1].empty?
            d.shift
          end
          r.shift
        end
        @data = result + d.reverse
        return self
      end
    protected
      def data; @data end
    private
      def independent( d )
        result = []
        d.each do | i |
          i[1].delete_if do | x | (x.class == NoChange) or (not x) end
          i[2].delete_if do | x | (x.class == NoChange) or (not x) end
          unless i[1].empty? and i[2].empty?
            result << [i[0], i[1].clone, i[2].clone]
          end
        end
        result
      end
    end
  end
end
