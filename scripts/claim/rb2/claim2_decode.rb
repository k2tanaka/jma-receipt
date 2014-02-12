#!/usr/bin/ruby
# coding : euc-jp
Encoding.default_external = "euc-jp" unless RUBY_VERSION == "1.8.7"


# Claim通信バージョン2
# 受信XMLのシーケンシャルファイルへの変換処理

# 2004/01/28 version2.00
#   ★XMLデータをリスト構造にすることで高速化
#     ただし、データ量の少ないファイルについては、速度は変わらない
#     大きいXMLファイルに対する効果が高く、
#     最も大きな物で90倍の高速化を確認している
#     なお、速度は設定ファイルの大きさに依存しているため、
#     設定ファイルのサイズが大きくなると遅くなるので、
#     設計には注意してほしい
#   ★設定ファイルをコンバートして生成する形をとることで、可読性を向上
#     いままで、設定ファイルの見栄えがかなり特殊だったが、
#     記述をXMLパスに似せた形にし、開始位置情報をなくすことで
#     設定ファイルは見やすくなっている。



# =============================================================================
# =============================================================================
# 直接実行したときの処理
if __FILE__ == $0


#	$debug = 0	# デバッグモードではない
#	$debug = 1	# デバッグモードである (レベル1)
#	$debug = 2	# デバッグモードである (レベル2)
	$debug = 3	# デバッグモードである (レベル3)

	# Debian環境ではEUC環境を、Windows環境ではシフトJIS環境を選択してください。
	$lang_conf = '1'	# EUC環境
#	$lang_conf = '2'	# シフトJIS環境



	# LineTarget定義で、空白にするXMLパスの置き換え文字
	$nodata_word = '<none>'

	help_flg = 0		# ヘルプ表示フラグ [0 = ヘルプを表示しない, 1 = ヘルプを表示する]
	$output_mode = 0	# 出力モード [0 = シーケンシャルファイル出力, 1 = CSVファイル出力]
						# 上記の出力モードがデフォルト
	w_file_name = []		# ファイル名の一時的な格納領域

	$hir_match_mode = 0		# 階層情報突き合わせモード[0 = 階層配列検索, 1 = 階層リスト検索]



	# 引数のセット処理
	ARGV.each do |w_a1|
		case	w_a1.strip
		when	'-s'
			# 出力するファイルはシーケンシャルファイル形式である
			$output_mode = 0
		when	'-c'
			# 出力するファイルはCSVファイル形式である
			$output_mode = 1
		when	'--lang=euc-jp'
			# 言語環境は、EUC-JPである
			$lang_conf = '1'
		when	'--lang=shift_jis'
			# 言語環境は、シフトJISである
			$lang_conf = '2'
		when	'--hierarcy-match=array'
			# 階層情報とのマッチングは、配列形式である
			$hir_match_mode = 0
		when	'--hierarcy-match=list'
			# 階層情報とのマッチングは、階層情報形式である
			$hir_match_mode = 1
		when	'--help', '-?'
			help_flg = 1
		else
			if (w_a1.strip)[0, 1] != '-'
				# １文字目がマイナス以外のその他のコマンドオプションはファイル名としてセットする
				w_file_name.push w_a1.strip
			end
		end
	end

	# ファイル名の数が少ないときは、エラー表示させる
	case	w_file_name.size
	when	0
		# ファイル名の指定がない
		help_flg = 1
	when	1, 2
		# ファイルの数が少ない
		$stderr.puts 'コマンドラインの引数にファイル名が指定されていません'
		$stderr.puts ''
		help_flg = 1
	else
		# ファイル名の指定が３つ以上なので、セットされた内容を渡す
		$hir_file = w_file_name[0]
		$xml_file = w_file_name[1]
		$seq_file = w_file_name[2]
	end


	if help_flg == 1
		$stderr.puts 'claim2_decode.rb [option] [階層定義ファイル] [入力XMLファイル] [出力ファイル]'
		$stderr.puts ''
		$stderr.puts '  [option]'
		$stderr.puts '    -s  シーケンシャルファイル出力 [default]'
		$stderr.puts '    -c  CSVファイル出力'
		$stderr.puts '    --lang=euc-jp     実行環境の文字コードがEUC-JPである(Default)'
		$stderr.puts '    --lang=shift_jis  実行環境の文字コードがShift_JISである(Windowsでの実行用)'
		exit 0
	end


	# 変数確認用の表示処理
	$stderr.puts '階層定義ファイル           = [' + $hir_file + ']'
	$stderr.puts '入力XMLファイル            = [' + $xml_file + ']'
	$stderr.puts '出力シーケンシャルファイル = [' + $seq_file + ']'



# =============================================================================
	# 別モジュール取り込み処理



end


require 'claim2_lib'
require 'xmlparser'
require 'kconv'
require 'uconv'
include Uconv



# =============================================================================
# =============================================================================
# クラス部


# XMLリスト基本クラス
class Xml_baselist


	# ------------------------------------------------------------
	# 初期化
	def initialize
		@flg = 0	# フラグ(0=データ、または、データなし, 1=属性)
		@name = ''	# タグ名・属性名
		@data = nil	# 実データ
		@list_value = 0	# 派生XMLリスト数
		@xmllist = []	# 派生XMLリスト
	end


	# ------------------------------------------------------------
	# XMLリスト基本クラスの生成
	#    引数
	# name - タグ名、または、属性名 [IN / String型]
	# flg - フラグ [IN / Numeric型]
	#          0 = データ、または、データなし
	#          1 = 属性
	# data - タグ、または、属性のデータ内容 [IN / String型]
	def childadd(name, flg, data)
		xml_newlist = Xml_baselist.new
		xml_newlist.name = name
		xml_newlist.flg = flg
		xml_newlist.data = data
		@xmllist.push xml_newlist
		@list_value += 1
		@xml_newlist = nil
		return	xml_newlist
	end


	# ------------------------------------------------------------
	# XMLパスをXMLパス配列形式に変換
	#    引数
	# xmlpath - 変換するXMLパス [IN / String型]
	#    戻り値
	# XMLパス配列
	#    備考
	# この関数は、相対パスを考慮した作りにはなっていませんので、
	# 相対パスで記述している場合は、絶対パスに変換してください。
	#    メモ
	# メンバー関数としては、あまり好ましくないが、
	# 配列形式でのやりとりを前提にしているので、とりあえずメンバー関数として作成する
	def convert_xml_path_to_patharray(xmlpath)
		xml_array = [] ; xml_array_size = 0 ; w_xmlpath = ''
		# 前後の空白を除去した上で、「/」の区切りで配列化する
		w_xmlpath = xmlpath.strip
		xml_array = w_xmlpath.split(/\//)
		# 配列の先頭が空白等なら、該当配列のみ削除
		case	xml_array[0]
		when	nil, ''
			xml_array.delete_at(0)
		end
		xml_array_size = xml_array.size
		if xml_array[xml_array_size - 1] =~ /\S@\S/
			word1 = '' ; word2 = []
			word1 = xml_array[xml_array_size - 1]
			word2 = word1.split(/@/)
			# ※「@」が２回以上出現することは考慮していません
			xml_array[xml_array_size - 1] = word2[0]	# 「@」より前をセット
			xml_array.push('@' + word2[1])	# 「@」以降をセット
		end
		return	xml_array
	end


	# ------------------------------------------------------------
	# 該当XMLパス(絶対パス形式のみ)配列のデータの取得
	#    引数
	# xmlpatharray - XMLパス配列 [IN / 配列(String)型]
	#    戻り値
	# 指定したXMLパス配列のデータ(nilの場合、取得できなかった) [OUT / String型]
	#    備考
	# 引数の配列は関数実行後の値を保証しません
	# 派生XMLリストのデータを取得する処理です
	def get_data_from_xmlpatharray(xmlpatharray)
		xml_tag = '' ; array_size = 0 ; xmllist_size = 0
		ret_data = nil
		xml_tag = xmlpatharray.shift
		if xml_tag == nil
			# nilの状態の場合は、例外を発生させる
			raise 'get_data_from_xmlpatharrayで例外が発生しました。' + "\n" + '引数のXMLパス配列にデータがありません。'
			# 例外が発生できない場合を考慮する
			return	nil
		end
		array_size = xmlpatharray.size
		xmllist_size = @xmllist.size
		if array_size > 0
			# 派生XMLリストの取得
			for x in 1..xmllist_size do

# ※XMLデータを読み込んだ時点で、配列形式の名前に置き換えていることを前提としている。

				if @xmllist[x - 1].name == xml_tag
					# シフト後のXMLパス配列を引数に指定して、派生XMLのデータ取得関数を呼び出す
					ret_data = @xmllist[x - 1].get_data_from_xmlpatharray(xmlpatharray.clone)
					break	# for文から抜ける
				end
				if x == xmllist_size
					# 派生XMLリストに該当するタグが見つからなかった場合は、nilを返す。
					ret_data = nil
				end
			end
		else
			# 派生XMLリストは検索しない
			# 指定したタグ名の値を取得
			if xml_tag[0, 1] == '@'
				# 属性のデータ取得である
				attr_tag = xml_tag
#				attr_tag = ''
#				attr_tag = xml_tag[1..-1]	# ２文字目以降を属性名として使用する
				for x in 1..xmllist_size do
					if @xmllist[x - 1].name == attr_tag
						ret_data = @xmllist[x - 1].data	# 実データを返す
						break	# for文から抜ける
					end
					if x == xmllist_size
						# 派生XMLリストに該当するタグが見つからなかった場合は、nilを返す。
						ret_data = nil
					end
				end
			else
				# タグのデータ取得である

# ※XMLデータを読み込んだ時点で、配列形式の名前に置き換えていることを前提としている。

				
				for x in 1..xmllist_size do
					if @xmllist[x - 1].name == xml_tag
						ret_data = @xmllist[x - 1].data	# 実データを返す
						break	# for文から抜ける
					end
					if x == xmllist_size
						# 派生XMLリストに該当するタグが見つからなかった場合は、nilを返す。
						ret_data = nil
					end
				end
			end
		end


	#    メモ
	# 配列に積むのは、/***[**]/****[**]/****[**]@***といったXMLパス
	# joinで「/」を区切ったあと、@が存在するかをチェックして、存在すれば、
	# 「@」で区切ったあと、最後の配列データに目印（先頭に「@」等）を付ける
	# 配列がnilになった時点で、データを取得する

		return ret_data
	end


	# ------------------------------------------------------------
	# LineTarget定義で使用するXMLパス配列のデータの取得
	#    引数
	# xmlpatharray - 検索対象XMLパス配列 [IN / 配列(String)型]
	# hierarcy_xmlpath - 呼び出し元XMLパス配列 [IN / 配列(String)型 / デフォルト = []]
	#    戻り値
	# []の場合 - 取得できなかった
	# []以外の場合
	#  [x][0] - 引数で指定したXMLパスが見つかった、実際のXMLパス [OUT / String型]
	#  [x][1] - 指定したXMLパス配列のデータ [OUT / String型]
	#    備考
	# 引数の配列は関数実行後の値を保証しません
	# 相対パスには対応していません
	# 配列を特定しない表現は「***[x]」というように、数字の代わりに「x」を指定します
	# 派生XMLリストのデータを取得する処理です
	# 通常は、「hierarcy_xmlpath」は指定しません。
	#   指定するケースは、この関数の中で再帰呼び出しをした場合のみでしょう。
	def get_data_from_xmlpatharray_reg(xmlpatharray, hierarcy_xmlpath = [])
		xml_tag = '' ; array_size = 0 ; xmllist_size = 0
		xml_tag2 = ''
		xml_tag3 = ''		# 配列番号なしのタグ名
		w_xml_path1 = ''	# XMLパススタックを文字列に変換した内容を格納する場所
		w_xml_path2 = []	# 子XMLリストに渡すXMLパス配列
		attr_tag = ''
		reg_flg = 0		# 正規表現フラグ(0 = 正規表現ではない, 1 = 正規表現である)
		ret_data = []
		xml_tag = xmlpatharray.shift
		if xml_tag == nil
			# nilの状態の場合は、例外を発生させる
			raise 'get_data_from_xmlpatharray_regで例外が発生しました。' + "\n" + '引数のXMLパス配列にデータがありません。'
			# 例外が発生できない場合を考慮する
			return	[]
		end

		# 配列部を除いたタグ名をxml_tag3にセットする
		xml_tag =~ /^(\S+?)\[[0-9x]+?\]/i
		xml_tag3 = $1

		array_size = xmlpatharray.size
		xmllist_size = @xmllist.size

		if xml_tag =~ /^(\S+?)\[x\]/i
			# ----------------------------------------
			# タグに正規表現を指定している
			# $1 = 配列部分を除いたタグ名
			xml_tag2 = Regexp.quote($1) + '\[[0-9]+?\]'	# 正規表現で比較できるようにする
			if array_size > 0
				# 派生XMLリストの取得
				for x in 1..xmllist_size do

# ※XMLデータを読み込んだ時点で、配列形式の名前に置き換えていることを全体としている。

					if @xmllist[x - 1].name =~ /#{xml_tag2}/
						# 子XMLリストに、現在のタグ名を加えて渡す
						w_xml_path2 = hierarcy_xmlpath.clone
						w_xml_path2.push @xmllist[x - 1].name
						# シフト後のXMLパス配列を引数に指定して、派生XMLのデータ取得関数を呼び出す
						ret_data += @xmllist[x - 1].get_data_from_xmlpatharray_reg(xmlpatharray.clone, w_xml_path2)
					end
					# 該当するタグが見つからなくても、ret_dataに対しては何もしない
				end
			else
				# 派生XMLリストは検索しない
				# 指定したタグ名の値を取得
				if xml_tag =~ /^(@\S+?)\[x\]/
					# 属性のデータ取得である
					# $1 = 「@」と配列部分を含めた属性名
					attr_tag = Regexp.quote($1)	# 正規表現で比較できるようにする
#					# $1 = 「@」と配列部分を除いた属性名
#					attr_tag = Regexp.quote($1) + '\[[0-9]\]'	# 正規表現で比較できるようにする
					for x in 1..xmllist_size do
						if @xmllist[x - 1].name =~ /#{attr_tag}/
							w_xml_path1 = '/' + hierarcy_xmlpath.join('/') + @xmllist[x - 1].name
#							w_xml_path1 = '/' + hierarcy_xmlpath.join('/') + '@' + @xmllist[x - 1].name
							ret_data.push [w_xml_path1, @xmllist[x - 1].data]	# 実データをスタックに積む
						end
						# 該当するタグが見つからなくても、ret_dataに対しては何もしない
					end
				else
					# タグのデータ取得である
					for x in 1..xmllist_size do
						if @xmllist[x - 1].name =~ /#{xml_tag2}/
							w_xml_path1 = '/' + hierarcy_xmlpath.join('/') + '/' + @xmllist[x - 1].name
							ret_data.push [w_xml_path1, @xmllist[x - 1].data]	# 実データをスタックに積む
						end
						# 該当するタグが見つからなくても、ret_dataに対しては何もしない
					end
				end
			end
			# ----------------------------------------
		else
			# ----------------------------------------
			# タグに正規表現を指定していない
			if array_size > 0
				# 派生XMLリストの取得
				for x in 1..xmllist_size do

# ※XMLデータを読み込んだ時点で、配列形式の名前に置き換えていることを前提としている。

					if @xmllist[x - 1].name == xml_tag
						# 子XMLリストに、現在のタグ名を加えて渡す
						w_xml_path2 = hierarcy_xmlpath.clone
						w_xml_path2.push @xmllist[x - 1].name
						# シフト後のXMLパス配列を引数に指定して、派生XMLのデータ取得関数を呼び出す
						ret_data += @xmllist[x - 1].get_data_from_xmlpatharray_reg(xmlpatharray.clone, w_xml_path2)
						break	# for文から抜ける
					end
					# 該当するタグが見つからなくても、ret_dataに対しては何もしない
				end
			else
				# 派生XMLリストは検索しない
				# 指定したタグ名の値を取得
				if xml_tag[0, 1] == '@'
					# 属性のデータ取得である
					attr_tag = xml_tag
#					attr_tag = ''
#					attr_tag = xml_tag[1..-1]	# ２文字目以降を属性名として使用する
					for x in 1..xmllist_size do
						if @xmllist[x - 1].name == attr_tag
							w_xml_path1 = '/' + hierarcy_xmlpath.join('/') + '@' + @xmllist[x - 1].name
							ret_data.push [w_xml_path1, @xmllist[x - 1].data]	# 実データをスタックに積む
							break	# for文から抜ける(正規表現でなければ可)
						end
						# 該当するタグが見つからなくても、ret_dataに対しては何もしない
					end
				else
					# タグのデータ取得である

# ※XMLデータを読み込んだ時点で、配列形式の名前に置き換えていることを前提としている。

					for x in 1..xmllist_size do
						if @xmllist[x - 1].name == xml_tag
							w_xml_path1 = '/' + hierarcy_xmlpath.join('/') + '/' + @xmllist[x - 1].name
							ret_data.push [w_xml_path1, @xmllist[x - 1].data]	# 実データをスタックに積む
							break	# for文から抜ける(正規表現でなければ可)
						end
						# 該当するタグが見つからなくても、ret_dataに対しては何もしない
					end
				end
			end
			# ----------------------------------------
		end

		# 配列データを戻り値として使用する
		return ret_data
	end

	# ※reg = regular expressionの略



	# ------------------------------------------------------------
	# 空データの派生XMLリストの削除
	#    備考
	# さらに派生しているXMLリストも考慮
	def del_nodataxmllist
		if @list_value > 0
			# 配列を削除すると、@list_valueの値が変わってしまうので、ワーク領域に固定値をセットする
			w_list_value1 = @list_value
			for m in 1..w_list_value1 do
				n = w_list_value1 - m
				if @xmllist[n].list_value > 0
					# 派生XMLリストからさらに派生しているので、派生XMLリストの空データ削除を実行する。
					@xmllist[n].del_nodataxmllist
				end

				# 再度派生するXMLリストがあるか、またはデータをチェックし、
				# 派生するXMLリストがなく、データもなければ、該当する派生XMLリストを削除する
				if @xmllist[n].list_value == 0
					# 派生XMLリストから派生しているXMLリストはない
					case	@xmllist[n].data
					when	nil, ''
						# 空白かnilである
						# 該当する派生XMLリストの配列を削除する
						@xmllist.delete_at(n)
						@list_value -= 1	# 現在の配列数をセットする
						# ※for分で、０から実行すると、配列オーバーや判定漏れを起こすので、
						#   かならず最後の配列から実行すること
					end
				end

			end

    	end
	end


	# ------------------------------------------------------------
	# 派生XMLリストの削除
	#    備考
	# 派生XMLリストから派生しているものに対しても削除処理をします。
	# 派生XMLリストに対しては、派生XMLリストオブジェクトのメソッドを実行します。
	def del_child
		if @list_value > 0
			# 派生XMLリストが存在する
			# 子オブジェクトの派生XMLリストの削除
			for x in 1..@list_value do
				@xmllist[x - 1].del_child
			end
			# 派生XMLリストの削除
			for x in 1..@list_value do
				@xmllist[x - 1] = nil
			end
			@xmllist = []
			# カウンタのクリア
			@list_value = 0
    	end
    end


	# ------------------------------------------------------------
	# オブジェクト外からのデータメンバーへのアクセスを可能にする
	attr_accessor :flg, :name, :data, :list_value, :xmllist
#	public :flg, :name, :data, :list_value, :xmllist
end



# =============================================================================


# 階層データリストクラス
# このクラスは、階層データをツリー構造に変換し、ツリー検索することで高速化するためのクラスです
# ただし、これは変換を行うたびに実行するとフラット形式よりも遅くなるため、
# 高速化するためには、受信サーバとの統合が必須です。

# 比較方法は、XMLリストを基準に構造単位の比較を行い、比較回数を減らすことで高速化が見込める。
# 起点値は、ファイルからの読み込み時に行う。


#    def initialize - 初期化
#    def child_create(name, byte) - 後ろに子階層情報の追加
#    def convert_xml_path_to_patharray(xmlpath) - XMLパスを配列形式のXMLパス配列に変換
#    def get_data_from_xmlpatharray(xmlpatharray) - 該当XMLパス配列の起点位置とバイト数の取得
#    @flg - フラグ(0=データ、または、データなし, 1=属性)
#    @name - 該当階層のタグ名 [String型]
#    @position - 該当階層のシーケンシャルファイルの起点位置 [Numeric型]
#    @byte - 該当階層のデータのバイト数 [Numeric型]
#    @seq_num - 項目番号 [Numeric型](CSV出力に使用)
#    @hirlist_value - 子階層情報の大きさ [Numeric型]
#    @hirlist - 子階層情報 [配列(オブジェクト)型]


# 階層データリストクラス
class HierarcydataList

	# ------------------------------------------------------------
	# 初期化
	def initialize
		@flg = 0			# フラグ(0=データ、または、データなし, 1=属性)
		@name = ''			# 該当階層のタグ名 [String型]
		@position = 0		# 該当階層のシーケンシャルファイルの起点位置 [Numeric型]
		@byte = 0			# 該当階層のデータのバイト数 [Numeric型]
		@seq_num = 0		# 項目番号 [Numeric型](CSV出力に使用)
		@hirlist_value = 0	# 子階層情報の大きさ [Numeric型]
		@hirlist = []		# 子階層情報 [配列(オブジェクト)型]
	end


	# ------------------------------------------------------------

	# 後ろに子階層情報の追加
	#    引数
	# name - タグ名、または、属性名 [IN / String型]
	# flg - フラグ [IN / Numeric型]
	#          0 = データ、または、データなし
	#          1 = 属性
	# position - 該当タグ・属性を書き込む起点位置 [Numeric型]
	# byte - 書き込むバイト数 [Numeric型]
	# seq_num - 項目番号 [Numeric型]
	#    戻り値
	# なし
	def childadd(name, flg, position, byte, seq_num = 0)
		hir_newlist = HierarcydataList.new
		hir_newlist.name = name
		hir_newlist.flg = flg
		hir_newlist.position = position
		hir_newlist.byte = byte
		hir_newlist.seq_num = seq_num
		@hirlist.push hir_newlist
		@hirlist_value += 1
		hir_newlist = nil
	end


	# ------------------------------------------------------------

	# XMLパスを配列形式のXMLパス配列に変換
	#    引数
	# xmlpath - 変換するXMLパス [IN / String型]
	#    戻り値
	# XMLパス配列
	#    備考
	# この関数は、相対パスを考慮した作りにはなっていませんので、
	# 相対パスで記述している場合は、絶対パスに変換してください。
	#    メモ
	# メンバー関数としては、あまり好ましくないが、
	# 配列形式でのやりとりを前提にしているので、とりあえずメンバー関数として作成する
	# 既に別のクラスに同じメンバー関数があるので、外部関数化してしまうのも手だろう
	def convert_xml_path_to_patharray(xmlpath)
		xml_array = [] ; xml_array_size = 0 ; w_xmlpath = ''
		# 前後の空白を除去した上で、「/」の区切りで配列化する
		w_xmlpath = xmlpath.strip
		xml_array = w_xmlpath.split(/\//)
		# 配列の先頭が空白等なら、該当配列のみ削除
		case	xml_array[0]
		when	nil, ''
			xml_array.delete_at(0)
		end
		xml_array_size = xml_array.size
		if xml_array[xml_array_size - 1] =~ /\S@\S/
			word1 = '' ; word2 = []
			word1 = xml_array[xml_array_size - 1]
			word2 = word1.split(/@/)
			# ※「@」が２回以上出現することは考慮していません
			xml_array[xml_array_size - 1] = word2[0]	# 「@」より前をセット
			xml_array.push('@' + word2[1])	# 「@」以降をセット
		end
		return	xml_array
	end


	# ------------------------------------------------------------

	# 該当XMLパス配列の起点位置とバイト数の取得
	#    引数
	# xmlpatharray - XMLパス配列 [IN / 配列(String)型]
	#    戻り値
	# 指定したXMLパス配列の起点位置とバイト数([]の場合、取得できなかった) [配列型(Numeric)型]
	#  [0] - 起点位置 [Numeric型]
	#  [1] - バイト数 [Numeric型]
	#    備考
	# 引数の配列は関数実行後の値を保証しません
	# 派生XMLリストのデータを取得する処理です
	def get_data_from_xmlpatharray(xmlpatharray)
		xml_tag = '' ; array_size = 0 ; hirlist_size = 0
		ret_data = []
		xml_tag = xmlpatharray.shift
		if xml_tag == nil
			# nilの状態の場合は、例外を発生させる
			raise 'get_data_from_xmlpatharrayで例外が発生しました。' + "\n" + '引数のXMLパス配列にデータがありません。'
			# 例外が発生できない場合を考慮する
			return	nil
		end
		array_size = xmlpatharray.size
		hirlist_size = @hirlist.size
		if array_size > 0
			# 派生XMLリストの取得
			for x in 1..hirlist_size do

# ※XMLデータを読み込んだ時点で、配列形式の名前に置き換えていることを前提としている。

				if @hirlist[x - 1].name == xml_tag
					# シフト後のXMLパス配列を引数に指定して、派生XMLのデータ取得関数を呼び出す
					ret_data = @hirlist[x - 1].get_data_from_xmlpatharray(xmlpatharray.clone)
					break	# for文から抜ける
				end
				if x == hirlist_size
					# 派生XMLリストに該当するタグが見つからなかった場合は、[]を返す。
					ret_data = []
				end
			end
		else
			# 派生XMLリストは検索しない
			# 指定したタグ名の値を取得
			if xml_tag[0, 1] == '@'
				# 属性のデータ取得である
				attr_tag = xml_tag
#				attr_tag = ''
#				attr_tag = xml_tag[1..-1]	# ２文字目以降を属性名として使用する
				for x in 1..hirlist_size do
					if @hirlist[x - 1].name == attr_tag
						# 属性名が見つかった
						ret_data.push @hirlist[x - 1].position	# 起点位置をセット
						ret_data.push @hirlist[x - 1].byte		# バイト数をセット
						break	# for文から抜ける
					end
					if x == hirlist_size
						# 派生XMLリストに該当するタグが見つからなかった場合は、[]を返す。
						ret_data = []
					end
				end
			else
				# タグのデータ取得である

# ※XMLデータを読み込んだ時点で、配列形式の名前に置き換えていることを前提としている。

				for x in 1..hirlist_size do
					if @hirlist[x - 1].name == xml_tag
						# タグ名が見つかった
						ret_data.push @hirlist[x - 1].position	# 起点位置をセット
						ret_data.push @hirlist[x - 1].byte		# バイト数をセット
						break	# for文から抜ける
					end
					if x == hirlist_size
						# 派生XMLリストに該当するタグが見つからなかった場合は、[]を返す。
						ret_data = []
					end
				end
			end
		end


		return ret_data
	end


	# ------------------------------------------------------------

	# 該当XMLパス配列の起点位置とバイト数の格納
	#    引数
	# xmlpatharray - XMLパス配列 [IN / 配列(String)型]
	# position - 起点位置 [Numeric型]
	# byte - バイト数 [Numeric型]
	# seq_num - 項目番号 [Numeric型]
	#    戻り値
	# なし
	#    備考
	# 引数の配列は関数実行後の値を保証しません
	# 派生XMLリストのデータを取得する処理です
	def put_data_from_xmlpatharray(xmlpatharray, position, byte, seq_num = 0)
		xml_tag = '' ; array_size = 0 ; hirlist_size = 0
		ret_data = nil	# 0 = 正常終了？

		xml_tag = xmlpatharray.shift
		if xml_tag == nil
			# nilの状態の場合は、例外を発生させる
			raise 'get_data_from_xmlpatharrayで例外が発生しました。' + "\n" + '引数のXMLパス配列にデータがありません。'
			# 例外が発生できない場合を考慮する
			return	nil
		end
		array_size = xmlpatharray.size
		hirlist_size = @hirlist.size
		if array_size > 0

			# x1 = for文用
			x2 = 0	# フラグ(0=該当するタグが見つからなかった,1=子階層に該当するタグが見つかった)
			x3 = 0	# 見つかった時の配列番号
			if hirlist_size > 0
				# 既にタグが存在するかを調べる
				for x1 in 0..(hirlist_size - 1) do
					if @hirlist[x1].name == xml_tag
						# 該当するタグが子階層から見つかった
						x2 = 1	# フラグのセット
						x3 = x1	# 配列番号のセット
						break	# for文から抜ける
					end
				end
			end

			# セットされたフラグを見て、子階層を作ったり、既存の子階層をターゲットにする
			case	x2
			when	0
				# 派生XMLリストに該当するタグが見つからなかった場合は、タグを作成する。

				# 子階層情報の追加(起点位置と書き込むバイト数は、両方とも0にした)
#				self.childadd(xml_tag, 0, 0, 0, seq_num)
				childadd(xml_tag, 0, 0, 0, seq_num)
				# 作成した子階層へXMLのデータを格納する
				ret_data = @hirlist[-1].put_data_from_xmlpatharray(xmlpatharray.clone, position, byte, seq_num)
				# ※最後の配列に対して行うので、配列指定は-1
				# ※タグのみなので、属性判定はしない
			when	1
				# シフト後のXMLパス配列を引数に指定して、派生XMLのデータ格納関数を呼び出す
				ret_data = @hirlist[x3].put_data_from_xmlpatharray(xmlpatharray.clone, position, byte, seq_num)
			else
				raise 'get_data_from_xmlpatharrayで例外が発生しました。' + "\n" + 'フラグ(x2)に不正な値がセットされました。x2 = [' + String(x2) + ']'
			end
		else
			# 派生XMLリストは検索しない
			# 指定したタグ名の値を取得
			if xml_tag[0, 1] == '@'
				# 属性のデータ取得である
				attr_tag = xml_tag
#				attr_tag = ''
#				attr_tag = xml_tag[1..-1]	# ２文字目以降を属性名として使用する

				# x1 = for文用
				x2 = 0	# フラグ(0=該当するタグが見つからなかった,1=子階層に該当するタグが見つかった)
				x3 = 0	# 見つかった時の配列番号
				if hirlist_size > 0
					# 既にタグ(属性)が存在するかを調べる
					for x1 in 0..(hirlist_size - 1) do
						if @hirlist[x1].name == attr_tag
							# 該当するタグ(属性)が子階層から見つかった
							x2 = 1	# フラグのセット
							x3 = x1	# 配列番号のセット
							break	# for文から抜ける
						end
					end
				end

				# セットされたフラグを見る
				# すでにタグ(属性)が存在する場合は、エラーを発生させる。
				case	x2
				when	0
					# 派生XMLリストに該当するタグ(属性)がないのを確認したので、子階層を作成する。
					childadd(xml_tag, 1, position, byte, seq_num)
				when	1
					# 属性名が見つかった
#					# 上書き書き込み
#					@hirlist[x].position = position
#					@hirlist[x].byte = byte
					# 上書き書き込みをせずに、エラーを発生させる
					raise 'put_data_from_xmlpatharrayで例外が発生しました。' + "\n" + '同じXMLパスに対して、上書き書き込みしようとしました。' + "\n" + 'XMLパス末尾 = [' + xml_tag + ']'
				else
					raise 'get_data_from_xmlpatharrayで例外が発生しました。' + "\n" + 'フラグ(x2)に不正な値がセットされました。x2 = [' + String(x2) + ']'
				end
			else
				# タグのデータ取得である

# ※XMLデータを読み込んだ時点で、配列形式の名前に置き換えていることを前提としている。

				# x1 = for文用
				x2 = 0	# フラグ(0=該当するタグが見つからなかった,1=子階層に該当するタグが見つかった)
				x3 = 0	# 見つかった時の配列番号
				if hirlist_size > 0
					# 既にタグが存在するかを調べる
					for x1 in 0..(hirlist_size - 1) do
						if @hirlist[x1].name == xml_tag
							# 該当するタグが子階層から見つかった
							x2 = 1	# フラグのセット
							x3 = x1	# 配列番号のセット
							break	# for文から抜ける
						end
					end
				end

				# セットされたフラグを見る
				# すでにタグが存在する場合は、エラーを発生させる。
				case	x2
				when	0
					# 派生XMLリストに該当するタグがないのを確認したので、子階層を作成する。
					childadd(xml_tag, 0, position, byte, seq_num)

				when	1
					# タグ名が見つかった
					if (@hirlist[x3].position == 0) and (@hirlist[x3].byte == 0)
						# まだ何も書かれていないタグである
						# 上書き書き込み
						@hirlist[x3].position = position
						@hirlist[x3].byte = byte
					else
						# すでに書き込まれているタグである
						# 上書き書き込みをせずに、エラーを発生させる
						raise 'put_data_from_xmlpatharrayで例外が発生しました。' + "\n" + '同じXMLパスに対して、上書き書き込みしようとしました。' + "\n" + 'XMLパス末尾 = [' + xml_tag + ']'
					end
				else
					raise 'get_data_from_xmlpatharrayで例外が発生しました。' + "\n" + 'フラグ(x2)に不正な値がセットされました。x2 = [' + String(x2) + ']'
				end

			end
		end


		return ret_data
	end


	# ------------------------------------------------------------
	# オブジェクト外からのデータメンバーへのアクセスを可能にする
	attr_accessor :flg, :name, :position, :byte, :seq_num, :hirlist_value, :hirlist
end



# =============================================================================


# XMLリストクラス
# このクラスは、XMLデータをツリー構造で保存し、ツリー検索することで高速化するためのクラスです

# メンバー関数
#   初期化
#   XMLデータの取り込み
#   XMLパス指定のデータ取得

# XMLリストクラス
class Xml_listdata

	# データメンバー
	attr_accessor :xmllist


	# ------------------------------------------------------------
	# 初期化
#	def initialize(x)
	def initialize
		# xmlのリストデータの初期化
		@xmllist = nil
	end


	# ------------------------------------------------------------
	# XMLデータの取り込み
	#    引数
	# xml_data - 取り込むXMLデータ [IN / String型]
	# out_word_code - 出力文字コード [IN / String型]
	#                    '1' - EUCコード
	#                    '2' - シフトJISコード
	#    戻り値
	# XMLリスト基本データオブジェクト(nilの場合、取り込みできなかった)
	#    備考
	# 前のバージョンでは、XMLパスに変換する形式だったが、
	#   今回はXMLリストオブジェクトを生成する方式をとる
	#   これにより、配列の検索対象の絞り込み
	def xmldata_setup(xml_data, out_word_code)
		ret_data = nil

		idx1 = 0	# ヘッダ判定で使用する
		idx2 = 0	# 配列化処理で使用する
		idx3 = 0	# 配列化処理で使用する


		flg1 = 0	# 配列化処理で使用する

		now_xmllist = nil	# 現在ターゲットにしているタグのxmllistオブジェクト
		xmllist_stack = []	# 入れ子に対応するためのxmllistオブジェクトのスタック領域

		wd_name1 = ''	# 名称のワーク領域(配列番号なし)
		wd_name2 = ''	# 名称のワーク領域(配列番号あり)
		wd_name3 = ''	# 名称のワーク領域(配列番号あり)

		wd_atrname1 = ''	# 属性名称のワーク領域
		wd_atrdata1 = ''	# 属性データのワーク領域

		wd_cdata1 = ''	# タグデータのワーク領域

		w_xml1 = ''	# XML文字列の格納場所
		i_encoding = ''	# 入力文字列の漢字コード
		o_encoding = ''	# 出力文字列の漢字コード


		# 出力文字列の漢字コードのセット
		case String(out_word_code)
		when '1'
			o_encoding = 'EUC-JP'
		when '2'
			o_encoding = 'Shift_JIS'
		when /EUC-JP/i
			o_encoding = 'EUC-JP'
		when /Shift_JIS/i
			o_encoding = 'Shift_JIS'
		end


		# １行目の取得
		idx1 = xml_data.index("\n")
		w_xml1 = xml_data[0, idx1]

		# ヘッダの変換
		# ※注意 : UTFの判定を先に行うこと()
		# encodingの記述がなければ、UTF-8として扱う
		if w_xml1 =~ /^.*?(<\?xml\sversion\s*?=\s*?\"[\.\d]+?\")\s*?(\?\>)/i 
#		if w_xml1 =~ /^.*?(<\?xml\sversion\s*?=\s*?\".+?\")\s*?(\?\>)/i 
			w_xml1 = $1 + " encoding=\"UTF-8\"" + $2 + "\n"
		end
		if w_xml1 =~ /^.*?(<\?xml\sversion\s*?=.+\sencoding\s*?=\s*?.UTF-8.*?)/i
			w_xml1.gsub!(/UTF-8/i, "UTF-8")
			i_encoding = "UTF-8"
		end
		if w_xml1 =~ /^<\?xml\sversion\s*?=.+\sencoding\s*?=\s*?.EUC-JP./i
			w_xml1.gsub!(/EUC-JP/i, "UTF-8")
			i_encoding = "EUC-JP"
		end
#		if w_xml1 =~ /^<\?xml\sversion=.+\sencoding=.Shift_JIS./i
		if w_xml1 =~ /^<\?xml\s*?version\s*?=.+\sencoding\s*?=\s*?.Shift_JIS./i
			w_xml1.gsub!(/Shift_JIS/i, "UTF-8")
			i_encoding = "Shift_JIS"
		end
		if w_xml1 =~ /^<\?xml\s*?version\s*?=.+\sencoding\s*?=\s*?.JIS./i
			w_xml1.gsub!(/JIS/i, "UTF-8")
			i_encoding = "JIS"
		end

		# 残りの文字列を取得して、変換
		w_xml1 += xml_data[idx1 .. -1]
		case i_encoding
		when "EUC-JP"
			w_xml1 = euctou8(w_xml1)
		when "Shift_JIS"
			w_xml1 = Uconv.euctou8(Kconv::toeuc(w_xml1))
#			w_xml1 = sjistou8(w_xml1)
		when "JIS"
			w_xml1 = Uconv::euctou8(Kconv::toeuc(w_xml1))
		when "UTF-8"
#			w_xml1 = w_xml1
			w_xml1 = euctou8(Uconv.u8toeuc(w_xml1))
#			if w_xml1[0] != '<'
#				w_xml1 = w_xml1[3 .. -1]		# ゴミが混じっていたら、取り除く
#			end
		else
			# 未対応の文字コードなので、例外を発生させる
			raise '入力された文字コードは対応していません [' + String(i_encoding) + ']'
		end


		# XMLリスト基本クラスの生成
		@xmllist = Xml_baselist.new


		parser = XMLParser.new
		def parser.default
		end

		now_xmllist = xmllist

		parser.parse(w_xml1) do |type, name, data|
			# ----------------------------------------
			case type
			when XMLParser::START_ELEM
				# 開始タグ
				case o_encoding
				when "EUC-JP"
					wd_name1 = Uconv.u8toeuc(name)
				when "Shift_JIS"
					wd_name1 = Kconv::tosjis(Uconv.u8toeuc(name))
#				when "UTF-8"
#					wd_name1 = name
				end

				# 現在のタグ名の配列化
				idx2 = 1	# 配列番号の初期化(1オリジン)
				if now_xmllist.list_value > 0
					# 派生XMLリストがあるので、名前がかぶらないかをチェック
					flg1 = 0	# 検索結果フラグの初期化(0 = 検索継続, 1 = 検索終了)
					while flg1 == 0 do
						flg1 = 1	# デフォルトで検索終了とする
						wd_name3 = wd_name1 + '[' + String(idx2) + ']'	# 検索するタグ名
						for idx3 in 0..(now_xmllist.list_value - 1) do
							if now_xmllist.xmllist[idx3].name == wd_name3
								# 一致する名前が見つかった
								flg1 = 0
								idx2 += 1	# 配列番号を加算する
								break	# for文から抜ける
							end
						end
					end
				end
				# タグ名に配列番号を付加する
				wd_name2 = wd_name1 + '[' + String(idx2) + ']'


				xmllist_stack.push now_xmllist	# スタックに、直前のxmllistオブジェクトを待避

				# 派生xmllistの作成
				now_xmllist = now_xmllist.childadd(wd_name2, 0, nil)	# dataの内容には、データなしを指定


				# 属性のセット
				# ※上記の派生xmllistの中に、属性データをセットする
				#
				data.each do |key, value|
					wd_atrname1 = '' ; wd_atrdata1 = ''		# デバッグが済んだら消すこと
					case o_encoding
					when "EUC-JP"
						wd_atrname1 = Uconv.u8toeuc(key)
						wd_atrdata1 = Uconv.u8toeuc(value)
					when "Shift_JIS"
						wd_atrname1 = Kconv::tosjis(Uconv.u8toeuc(key))
						wd_atrdata1 = Kconv::tosjis(Uconv.u8toeuc(value))
#					when "UTF-8"
#						wd_atrname1 = key
#						wd_atrdata1 = value
					end
					# 派生xmllistに属性データをセット
					now_xmllist.childadd(('@' + wd_atrname1), 1, wd_atrdata1)
				end

			# ----------------------------------------
			when XMLParser::END_ELEM
				# 終了タグ
				# 対象タグを、ひとつ上位のタグに戻す
				now_xmllist = xmllist_stack.pop

			# ----------------------------------------
			when XMLParser::CDATA
				# タグのデータ内容
				if data != nil
					# dataの内容はnilではない
					case o_encoding
					when "EUC-JP"
						wd_cdata1 = Uconv.u8toeuc data
					when "Shift_JIS"
#						wd_cdata1 = Uconv.u8toeuc data
#						wd_cdata1 = Kconv::tosjis c_data
						wd_cdata1 = Kconv::tosjis(Uconv.u8toeuc(data))
#						wd_cdata1 = Uconv.u8tosjis data
#					when "UTF-8"
#						wd_cdata1 = data
					end
					wd_cdata1.strip!	# 前後の空白を除去する
					# 内容が空白の場合は、nilにする
					wd_cdata1 = nil			if wd_cdata1 == ''
				else
					# dataの内容がnilである
					wd_cdata1 = nil
				end
				if wd_cdata1 != nil
					# dataがnilでない場合、対象オブジェクトに内容をセット
					now_xmllist.data = wd_cdata1
				end
			# ----------------------------------------
			when XMLParser::PI
#			when XMLParser::START_DOCTYPE_DECL
#			when XMLParser::END_DOCTYPE_DECL
			when XMLParser::DEFAULT
			else
			end
		end


		return ret_data
	end


	# ------------------------------------------------------------
	# XMLパスのデータの取得(絶対パス形式のみ)
	#    引数
	# xmlpath - 取得したいXMLパス [IN / String型]
	#    戻り値
	# 指定したXMLパスの内容(nilの場合、取得できなかった)
	#    備考
	# 引数のXMLパスは関数実行後の値を保証しません
	# 派生XMLリストのデータを取得する処理です
	# 引数に指定するのは、絶対パス形式で行ってください
	#   相対パスには対応していません
	def get_xmlpath_data(xml_path)
		return (@xmllist.get_data_from_xmlpatharray(@xmllist.convert_xml_path_to_patharray(xml_path)))
	end


	# ------------------------------------------------------------
	# XMLデータの内部形式の確認(デバッグ用)
	#    引数
	# show_mode - 表示モード [IN / Numeric型 / デフォルト値 = 10]
	#                10 - デバッグ向けの表示モード
	#    戻り値
	# なし
	#    備考
	# このメンバー関数は、内部データが正しく格納されているかを確認するために作成しました
	# この関数自体のデバッグも、気を付けること
	def print_xmllist(show_mode = 10)
		now_xmllist = nil			# 現在のXMLリストオブジェクト
		now_xmllist_index = 0		# 現在の対象派生XMLリストオブジェクトのインデックス値
		xmllist_stack = []			# XMLリストオブジェクトのスタック
		xmllist_index_stack = []	# XMLリストオブジェクトのインデックス値のスタック

		case	show_mode
		# ----------------------------------------
		# デバッグ向けの表示モード
		when	10
			now_xmllist = @xmllist
			now_xmllist_index = 0
			if now_xmllist == nil
				puts 'XMLリストオブジェクトはnilです'
			elsif now_xmllist.list_value == 0
				# XMLリストの数が０である
				puts 'XMLリストデータが存在しません'
			else
				# XMLリストを表示する
				while true do
					case	now_xmllist.flg
					when	0
						# タグ、または、データなし
						if now_xmllist_index == 0
							# インデックスが0の時のみ表示する
							# (子XMLリストから戻ってきたときにも表示されるのを防ぐため)
							case	now_xmllist.name
							when	nil
								# タグ名・属性名にnilがセットされている
								puts 'タグ名がnilです'
							when	''
								# タグ名・属性名に空白がセットされている
								puts 'タグ名が空白です'
							else
								# タグ名・属性名に文字列がセットされている
								case	now_xmllist.data
								when	nil, ''
									# タグのみである
								else
									# 内容が存在する
									puts ':' + now_xmllist.name + ' = [' + now_xmllist.data + ']'
								end
							end
						end

					when	1
						# 属性
						case	now_xmllist.name
						when	nil
							# 属性名にnilがセットされている
							puts '属性名がnilです'
						when	''
							# 属性名に空白がセットされている
							puts '属性名が空白です'
						else
							# 属性名に文字列がセットされている
							case	now_xmllist.data
							when	nil
								# 属性にnilが入っている
								puts ':' + now_xmllist.name + ' = [nil]'
							when	''
								# 属性に空白が入っている
								puts ':' + now_xmllist.name + ' = [空白]'
							else
								# 内容が存在する
								puts ':' + now_xmllist.name + ' = [' + now_xmllist.data + ']'
							end
						end
					else
						puts 'XMLリストのフラグに不正な値がセットされています'
						puts '   flg = [' + String(now_xmllist.flg) + ']'
					end

					# 派生XMLリストがあれば、スタックにインデックスとオブジェクトをセットして、現在のXMLリストオブジェクト領域に、子XMLリストをセットする
					if now_xmllist_index < now_xmllist.list_value
						# 現在の内容をスタックにセット
						xmllist_stack.push now_xmllist
						xmllist_index_stack.push now_xmllist_index
						# 現在の内容を、子XMLリストにする
						now_xmllist_index = 0
						now_xmllist = now_xmllist.xmllist[0]
						puts '>' + now_xmllist.name
					else
						# 子XMLリストがないので、元のオブジェクトにする
						while	((now_xmllist != nil) && (now_xmllist_index >= now_xmllist.list_value)) do
							puts '<' + now_xmllist.name
							now_xmllist_index = xmllist_index_stack.pop
							now_xmllist_index += 1	# 次のXMLリストに移る
							now_xmllist = xmllist_stack.pop
						end
						# 最上位のXMLリストから抜けたら、while文から抜けて処理を終了する
						if now_xmllist == nil
							puts 'XML End'
							break
						end
					end
				end
			end
		# ----------------------------------------
		end

		nil
	end


	# ------------------------------------------------------------
	# LineTarget定義処理
	#    引数
	# hierarcy_data - LineTarget定義処理を行う階層情報 [IN / String型]
	#    戻り値
	# nil - エラーが発生した
	# nil以外 - 変換後の階層情報
	#    備考
	# 参照するXMLリストデータは、このXMLオブジェクトのXMLリストデータです
	# 実行前に、コメントを外したり、無駄な空白行を削除してください
	# このメンバー関数は、階層情報オブジェクトがあった場合、
	#   そちらのメンバー関数に含むべきもの。
	#   もしも、階層情報オブジェクトのクラスを作成した場合は、
	#   引数を階層情報からXMLリストオブジェクトに変えること。
	# 相対パスは変換できません
	def exec_LineTargetDefinition(hierarcy_data)
		ret_data = nil ; h_data = ''
		define_startline = '' ; define_symbol = '' ; define_param = ''
		define_endline = ''

		h_data1 = hierarcy_data.clone	# 念のため、新しい領域を確保してのコピー

		while h_data1 =~ /^(\s*?\$LineTargetStart\s*?,\s*?(\S+?)\s*?,(.+?)\n)/i
			# LineTarget定義がパラメータデータに存在する
			# $1 = LineTarget定義が出現した行
			# $2 = LineTarget定義のシンボル名
			# $3 = シンボル名から後のパラメータ情報
			define_startline = $1
			define_symbol = $2
			define_param = $3

			# LineTarget定義の終了位置の取得
			if h_data1 =~ /^(\s*?\$LineTargetEnd\s*?,\s*?#{define_symbol}\s*?)/i
				# $1 = 終了LineTargetEnd定義が出現した行
				define_endline = $1
			else
				$stderr.puts '$LineTargetEnd定義が存在しません (シンボル名 = ' + String(define_symbol) + ')'
				exit 2
			end

			# 取得した内容を、正規表現で使えるように変換
			define_startline = Regexp.quote(define_startline)
			define_endline = Regexp.quote(define_endline)

			define_before = ''	# LineTarget定義変換前の対象
			define_after = ''	# LineTarget定義変換後の対象
			if h_data1 =~ /(#{define_startline}([\s\S]*?)#{define_endline})/
				# $1 - 置換前対象
				# $2 - 置換後対象
				define_before = $1.clone			# 置換前内容の格納領域
 				define_after = $2.clone			# 置換後内容の格納領域
			end


			# パラメータ情報の取得
			w_arg1 = []
			w_arg2 = []
			w_arg1 = define_param.split ','		# 「,」区切りで抜き出す
			w_arg1.each_index do |w_idx1|
				# 各配列の空白削除処理
				w_arg1[w_idx1].strip!
			end
			w_arg2 = w_arg1[0].split '='	# ２番目の引数のみ「=」区切りでさらに抜き出す
			w_arg2.each_index do |w_idx2|
				# 各配列の空白削除処理
				w_arg2[w_idx2].strip!
			end
			base_hierarcy = w_arg1[2]			# 基準階層の取得
			mean_decision = '='					# 判定方法（現在、「=」で固定）
			decision_hierarcy = w_arg2[0]		# 判定階層
			decision_value = w_arg2[1]			# 判定内容
			if decision_value[0, 1] == "\"" and decision_value[-1, 1] == "\""
				decision_value = decision_value[1, (decision_value.size - 2)]
			end
			arg_num = Integer(w_arg1[1]) - 1	# 対象配列番号(階層情報ファイルには、１オリジンで記述)

			# +++++
			find_flg1 = 0	# 検索フラグ
			# +++++


			# 判定階層の名称と内容を取得
			w_arg3 = []
			w_arg3 = @xmllist.get_data_from_xmlpatharray_reg(@xmllist.convert_xml_path_to_patharray(decision_hierarcy))
			if w_arg3 == nil or w_arg3.size == 0
				# +++++
				find_flg1 = 1	# 検索フラグのセット
				# +++++
#				$stderr.puts '階層データが存在しません (判定階層 = ' + String(decision_hierarcy) + ')'
#				exit 2
			end

			# 取得した内容と判定内容比較
			# 内容とLineTargetの引数の「内容」と比較し、同じ物をスタックにセット
			# +++++
			if find_flg1 == 0
			# +++++
				h_name_arg1 = []
				h_value_arg1 = []
				w_arg3.each do |e1|
					if e1[1] == decision_value
						# 取得内容と判定内容が一致したので、配列にセットする
						h_name_arg1.push e1[0]
						h_value_arg1.push e1[1]
					end
				end
				if h_value_arg1 == nil or h_value_arg1 == []
					# +++++
					find_flg1 = 2	# 検索フラグのセット
					# +++++
#					$stderr.puts '指定された階層に該当の内容が存在しません (判定階層 = ' + String(decision_hierarcy) + ') = (' + decision_value + ')'
#					exit 2
				end
			# +++++
			end
			# +++++


			# ターゲット配列の抽出
			# 引数の「ｎ番目」を取得し、見つかったものを変数領域にセット
			# +++++
			if find_flg1 == 0
			# +++++
				h_name1 = ''
				h_value1 = ''
				h_name1 = h_name_arg1[arg_num]
				h_value1 = h_value_arg1[arg_num]
				if h_name1 == nil
					# +++++
					find_flg1 = 3	# 検索フラグのセット
					# +++++
#					$stderr.puts '指定された配列の階層に該当の内容が存在しません (判定階層 = ' + String(decision_hierarcy) + ') = (' + decision_value + ') (配列 = ' + String(arg_num) + ')'
#					exit 2
				end
			# +++++
			end
			# +++++


			# +++++
			if find_flg1 == 0
			# +++++
				# 階層が見つかった
				# この時点で、h_name1に該当する階層情報が入っている

				# LineTargetの基準階層と比較（合わない場合は、致命的エラー）し、
				# その後、基準階層部分の正規表現と一致する該当階層と、
				# 起点〜終点の間（LineTarget定義を含めない）の変数に対して、置換を行う。
				# その後、階層情報全体に対して、置換処理を行う。
				# （置換処理は、gsubを使わない方法を使用）

#				h_name2 = exchange_hierarcy_name(1, base_hierarcy)		# 基準階層を、変換する
				# 基準階層を、正規表現で指定できるように変換する
				h_name2 = Regexp.quote(base_hierarcy).gsub /\\\[x\\\]/i, '\[[0-9]+?\]'

				# 同じものが見つかった場合、基準階層の抽象表現を、実表現に変換する
				if h_name1 =~ /(#{h_name2})/
					# 基準階層の正規表現と判定階層が一致した
					h_name3 = $1	# 基準階層の実階層名の取得
					# 基準階層名と実階層名の置換処理
					define_after.gsub! /#{Regexp.quote(base_hierarcy)}/, h_name3
					# 全体に対しての置換処理(ここが、実置換処理である)
#					h_data1.gsub! /#{Regexp.quote(define_before)}/, define_after
#					h_data1.gsub! Regexp.quote(define_before), define_after

					w_idx1 = 0 ; w_idx2 = 0 ; w_idx3 = 0
					w_idx1 = h_data1.index define_before		# 変換前文字列を検索する
					w_idx2 = define_before.size
					w_idx3 = h_data1.size
					h_data1 = h_data1[0 .. (w_idx1 - 1)] + define_after + h_data1[(w_idx1 + w_idx2) ... w_idx3]


				else
					# 基準階層の正規表現と判定階層が一致しなかった
					$stderr.puts '判定階層は、基準階層の中になければなりません (判定階層 = ' + String(decision_hierarcy) + '), (基準階層 = ' + base_hierarcy + ')'
					exit 2
				end
			# +++++
			else
				# 階層が見つからなかった
# ※いままで、ここで削除するロジックを組み込んでいたが、そうすると、
#   階層情報に起点位置情報がないため、重大なバグが発生する。
#   対処方法は、代替文字でXMLデータを置き換える方法をとる

				w_define_after1 = []
				w_define_after1 = define_after.split "\n"

				w_define_after1.each_index do |w_aryidx1|
					if w_define_after1[w_aryidx1] =~ /^\s*?\S+?\s*?\=\s*?([\S\s]+?)\s*?$/
						# $1 - バイト数等の文字列
						w_define_after1[w_aryidx1] = $nodata_word + '=' + $1
					end
				end
				define_after = w_define_after1.join "\n"
				# 最後の文字が改行でない場合は、改行を追加する
				if define_after[-1, 1] != "\n"
					define_after += "\n"
				end
				w_idx1 = 0 ; w_idx2 = 0 ; w_idx3 = 0
				w_idx1 = h_data1.index define_before		# 変換前文字列を検索する
				w_idx2 = define_before.size
				w_idx3 = h_data1.size
				h_data1 = h_data1[0 .. (w_idx1 - 1)] + define_after + h_data1[(w_idx1 + w_idx2) ... w_idx3]
				# 下記は、以前のコード
				# ----------
# 				# 該当場所の内容を削除してしまう(階層がないとみなす)
# #				h_data1.gsub! /#{Regexp.quote(define_before)}/, ''
# 				# 上記gsubを使うと、長すぎて異常終了するので、以下の方法で代用
# 				w_idx1 = 0 ; w_idx2 = 0 ; w_idx3 = 0
# 				w_idx1 = h_data1.index define_before		# 変換前文字列を検索する
# 				w_idx2 = define_before.size
# 				w_idx3 = h_data1.size
# 				h_data1 = h_data1[0 .. (w_idx1 - 1)] + h_data1[(w_idx1 + w_idx2) ... w_idx3]
				# ----------
			end
			# +++++

		end		# while文
				# ここまでは、LineTarget定義の回数分繰り返す（while文）


# 念のため、いままでのコードにあった「抽象階層情報(***[x])を実階層情報に変換」を組み込む
# # このコードに意味があるのか不明
# # 後で、デバッグコードを組み込んで、確かめてみること

		# 抽象階層情報を実階層情報に変換
		while h_data1 =~ /^\s*?(.*?\([xX]\).*?)\s*?=.*?\n/
			# $1 = 階層名
			w_hname = $1.strip
			r1_data = []
			r1_data = @xmllist.get_data_from_xmlpatharray_reg(@xmllist.convert_xml_path_to_patharray(w_hname))
			if r1_data == nil or r1_data.size == 0
				# 指定された階層データは、存在しない
				$stderr.puts '指定された階層データは存在しません {' + String(w_hname) + ']'
				exit 2
			end
			r2_data = r1_data[0]
			w_hname = Regexp.quote(w_hname)	# 正規表現に使える形式に変換
			h_data1.gsub! /#{w_hname}/, r2_data[0]	# 置換処理
		end


		return	h_data1
	end



	# ------------------------------------------------------------
	# 階層情報データの変換(フラット配列データ形式)
	#    引数
	# hierarcy_data - 階層情報データ [IN / String型]
	# out_word_code - 出力文字コード [IN / String型]
	#                    '1' - EUCコード
	#                    '2' - シフトJISコード
	#    戻り値
	# []の場合
	# []でない場合
	#   [x][0] - XMLパス [OUT / String型]
	#   [x][1] - バイト数 [OUT / Integer型]
	#    備考
	# このメンバー関数では、引数に渡した元の階層情報データに対して
	# LineTarget定義処理を行い、XMLパスとバイト数に分けた２次配列の内容を返します
	# 実行後の引数の階層情報データの値は保証されません
	def exchange_hierarcy_to_harray(hierarcy_data, out_word_code)
		ret_data = []
		h_data0 = ''
		h_data1 = ''
		h_data2 = []
		xml_path1 = ''
		seq_byte1 = ''
		w_idx1 = 0	# エラー表示に役立てるための領域



		# バージョン・言語チェックと変換
		first_line = ''	# １行目の内容をセットする領域
		hfdef_flg = []	# 行頭から解析した内容をセットする領域
		hierarcy_data =~ /^([^\n]+?)\n/
		first_line = $1	# １行目の内容をセット
		# 行頭認識処理の実行
		hfdef_flg = realize_topline(first_line)
		if hfdef_flg[0] != 5
			$stderr.puts '引数に指定された階層ファイルのヘッダの内容が、無効です。'
			$stderr.puts '実行時用の階層ファイルか、または古い階層データではないか確認してください。'
			exit 1
		end
		if hfdef_flg[1] != 2
			$stderr.puts '階層ファイルのヘッダのメジャーバージョンが2以外です。'
			$stderr.puts 'このスクリプトは、メジャーバージョン2以外には対応していません。'
			exit 1
		end
		case	hfdef_flg[3]
		when	0
			# 未定義か未定義の文字コードである
			$stderr.puts 'ヘッダに文字コードが指定されていません。'
			$stderr.puts 'ヘッダに文字コードを記述してから、実行してください。'
			exit 1
		when	1
			# 入力階層ファイルはEUC-JPコード
			case	out_word_code
			when	'1'
				# 変換後の文字コードはEUCコード
				h_data0 = hierarcy_data
#				h_data0 = Kconv::toeuc(hierarcy_data)
			when	'2'
				# 変換後の文字コードはシフトJISコード
				h_data0 = Kconv::tosjis(hierarcy_data)
				# 改行コードの変換
				while	h_data0 =~ /[^\x0d]\x0a/
					h_data0.gsub! /([^\x0d])\x0a/, '\1'+"\x0d\x0a"
				end
			end
		when	2
			# 入力階層ファイルはShift_JISコード
			case	out_word_code
			when	'1'
				# 変換後の文字コードはEUCコード
				h_data0 = Kconv::toeuc(hierarcy_data)
				# 改行コードの変換 (windowsでは不要だが、debian側では必要)
				while	h_data0 =~ /\x0d\x0a/
					h_data0.gsub! /\x0d\x0a/, "\x0a"
				end
			when	'2'
				# 変換後の文字コードはシフトJISコード
				h_data0 = hierarcy_data
#				h_data0 = Kconv::tosjis(hierarcy_data)
			end
		when	3
			# 入力階層ファイルはUTF-8コード
			case	out_word_code
			when	'1'
				# 変換後の文字コードはEUCコード
				h_data0 = Uconv.u8toeuc(hierarcy_data)
			when	'2'
				# 変換後の文字コードはシフトJISコード
				h_data0 = Kconv::tosjis(Uconv.u8toeuc(hierarcy_data))
				# 改行コードの変換
				while	h_data0 =~ /[^\x0d]\x0a/
					h_data0.gsub! /([^\x0d])\x0a/, '\1'+"\x0d\x0a"
				end
			end
		when	4
			# 入力階層ファイルはJISコード
			case	out_word_code
			when	'1'
				# 変換後の文字コードはEUCコード
				h_data0 = Kconv::toeuc(hierarcy_data)
			when	'2'
				# 変換後の文字コードはシフトJISコード
				h_data0 = Kconv::tosjis(hierarcy_data)
				# 改行コードの変換
				while	h_data0 =~ /[^\x0d]\x0a/
					h_data0.gsub! /([^\x0d])\x0a/, '\1'+"\x0d\x0a"
				end
			end
		end


		# コメントと行前後の空白を除去
		h_data1 = record_del_comment_space(h_data0)

		# 「=」の前後の空白を除去
		while  /\=[^\S\n]+?/ =~ h_data1
			h_data1.gsub! /\=[^\S\n]+?/ , '='
		end
		while  /\s+?\=/ =~ h_data1
			h_data1.gsub! /\s+?\=/ , '='
		end

		# LineTarget処理
		h_data1 = exec_LineTargetDefinition(h_data1)
		if h_data1 == nil
			# 関数内でエラーが発生した
			raise '「exec_LineTargetDefinition」関数で、エラーが発生しました。(exchange_hierarcy_to_harray)'
			# 例外が発生できない場合を考慮する
			return	nil
		end


		# 改行単位で配列化
		h_data2 = h_data1.split("\n")

		w_idx1 = 0

		h_data2.each do |h_data_ex1|
			w_idx1 += 1
			if h_data_ex1 =~ /^\s*?(\S+?)\s*?\=\s*?(\S+?)\s*?$/
				# $1 = XMLパス
				# $2 = バイト数
				xml_path1 = $1
				seq_byte1 = $2
#				seq_byte1.gsub /^([0-9]*?)[^0-9]??\S*?$/, '\1'	# 書式が変わっても大丈夫なように先手をうつ
				seq_byte1.gsub! /^\s*?([0-9]+?)\s*?,[\S\s]*?$/, '\1'	# 書式が変わっても大丈夫なように先手をうつ
				ret_data.push [xml_path1, Integer(seq_byte1)]
			else
				raise '階層情報の中に、不正な記述を発見しました。(ほぼ' + String(w_idx1) + '行目付近)' + "\n" + '[' + h_data_ex1 + ']'
				# 例外が発生できない場合を考慮する
				return	nil
			end
		end


		return ret_data
	end


	# ------------------------------------------------------------
	# XMLデータのシーケンシャル情報への変換(フラット配列データ形式)
	#    引数
	# hierarcy_data - 階層情報データ [IN / String型]
	# output_mode   - 出力モード [IN / Integer型]
	#                    0 - シーケンシャルファイル出力
	#                    1 - CSVファイル出力
	# out_word_code - 出力文字コード [IN / String型]
	#                    '1' - EUCコード
	#                    '2' - シフトJISコード
	#    戻り値
	# シーケンシャルデータ [OUT / 配列(String)型] ([]の場合、エラー)
	#    備考
	# この関数の実行前に「xmldata_setup」メンバー関数を実行してください。
	# 実行後の引数の内容は保証されません
	# 高速化のため、シーケンシャルデータは配列型にしています。
	# ファイル書き込みの際に、順番に書き込んでもらえば通常の文字列を書き込むのと同等になります
	def convert_xmldata_to_sequenthdata(hierarcy_data, output_mode, out_word_code)
		ret_data = []
		h_array1 = []
		w_idx1 = 0
		xml_data1 = ''
		xml_size1 = 0


		# 「xmldata_setup」の実行チェック
		if @xmllist == nil
			raise '「xmllist」データメンバーがnilです。「xmldata_setup」が実行されなかったか、エラーが発生していると思われます。'
			# 例外が発生できない場合を考慮する
			return	[]
		end


		# 階層情報データを階層情報配列データに変換する
		h_array1 = exchange_hierarcy_to_harray(hierarcy_data, out_word_code)
		if h_array1 == []
			# 階層情報が存在しない
			return []
		end

		w_idx1 = 0	# 起点位置
		h_array1.each do |h_data1|
			# h_data1[0] - XMLパス [OUT / String型]
			# h_data1[1] - 文字数 [OUT / Integer型]
			if h_data1[0] != $nodata_word
				# LineTarget定義で消されていないデータである
				xml_data1 = @xmllist.get_data_from_xmlpatharray(@xmllist.convert_xml_path_to_patharray(h_data1[0]))
			else
				# LineTarget定義で消されたデータである
				xml_data1 = nil
			end

			if xml_data1 != nil
				# XMLデータが見つかった
				xml_size1 = xml_data1.size	# 文字数の取得
				if xml_size1 < h_data1[1]
					# 該当XMLパスのデータは、シーケンシャルファイルに書き込む文字数より小さい
					ret_data.push xml_data1
					if output_mode != 1		# CSV出力の場合は、空白はセットしない
						ret_data.push(' ' * (h_data1[1] - xml_size1))	# 足りない文字数分空白をセット
					end
				elsif xml_size1 > h_data1[1]
					# 該当XMLパスのデータは、シーケンシャルファイルに書き込む文字数より大きい
					$stderr.puts '該当文字は長すぎるので、値を切り捨てます' + "\n" + '切り捨て前[' + xml_data1 + ']'
					ret_data.push xml_data1[0, h_data1[1]]	# 書き込める文字数のみ書き込み
					$stderr.puts '切り捨て後[' + xml_data1[0, h_data1[1]] + ']'
				else
					# 該当XMLパスのデータは、シーケンシャルファイルに書き込む文字数と同じ
					ret_data.push xml_data1	# そのまま文字列をセット
				end
				w_idx1 += h_data1[1]
			else
				# XMLデータが見つからなかった
				if output_mode != 1		# CSV出力の場合は、空白はセットしない
					ret_data.push(' ' * h_data1[1])	# 指定文字数数空白をセット
					w_idx1 += h_data1[1]
				end
			end
			if output_mode == 1
				# CSVファイル出力である
				ret_data.push ','
			end

		end
		if output_mode == 1
			# CSVファイル出力である
			if ret_data[-1] == ','
				# 最後の「,」を削除する
				ret_data.pop
			end
		end


		return ret_data
	end

	# 旧コードの「set_sequenth_xmldata」関数に相当




	# ------------------------------------------------------------
	# 階層情報データの変換(階層リストデータ形式)
	#    引数
	# hierarcy_data - 階層情報データ [IN / String型]
	# out_word_code - 出力文字コード [IN / String型]
	#                    '1' - EUCコード
	#                    '2' - シフトJISコード
	#    戻り値
	# nilか[]の場合 - 階層情報の変換に失敗した
	# nilか[]でない場合
	#  [0] - 階層情報リストデータ [OUT / オブジェクト型]
	#  [1] - 出力件数 [OUT / Numeric型]
	#  [2] - 全体のシーケンシャルデータのバイト数 [OUT / Numeric型]
	#    備考
	# このメンバー関数では、引数に渡した元の階層情報データに対して
	# LineTarget定義処理を行い、階層リストデータを返します
	# 実行後の引数の階層情報データの値は保証されません
	def exchange_hierarcy_to_hierarcylist(hierarcy_data, out_word_code)
		ret_data = nil
		h_data0 = ''
		h_data1 = ''
		h_data2 = []
		xml_path1 = ''
		seq_byte1 = ''
		seq_byte2 = 0
		seq_point1 = 0
		w_idx1 = 0	# CSV出力に使う番号と、エラー表示に役立てるための領域



		# バージョン・言語チェックと変換
		first_line = ''	# １行目の内容をセットする領域
		hfdef_flg = []	# 行頭から解析した内容をセットする領域
		hierarcy_data =~ /^([^\n]+?)\n/
		first_line = $1	# １行目の内容をセット
		# 行頭認識処理の実行
		hfdef_flg = realize_topline(first_line)
		if hfdef_flg[0] != 5
			$stderr.puts '引数に指定された階層ファイルのヘッダの内容が、無効です。'
			$stderr.puts '実行時用の階層ファイルか、または古い階層データではないか確認してください。'
			exit 1
		end
		if hfdef_flg[1] != 2
			$stderr.puts '階層ファイルのヘッダのメジャーバージョンが2以外です。'
			$stderr.puts 'このスクリプトは、メジャーバージョン2以外には対応していません。'
			exit 1
		end
		case	hfdef_flg[3]
		when	0
			# 未定義か未定義の文字コードである
			$stderr.puts 'ヘッダに文字コードが指定されていません。'
			$stderr.puts 'ヘッダに文字コードを記述してから、実行してください。'
			exit 1
		when	1
			# 入力階層ファイルはEUC-JPコード
			case	out_word_code
			when	'1'
				# 変換後の文字コードはEUCコード
				h_data0 = hierarcy_data
#				h_data0 = Kconv::toeuc(hierarcy_data)
			when	'2'
				# 変換後の文字コードはシフトJISコード
				h_data0 = Kconv::tosjis(hierarcy_data)
				# 改行コードの変換
				while	h_data0 =~ /[^\x0d]\x0a/
					h_data0.gsub! /([^\x0d])\x0a/, '\1'+"\x0d\x0a"
				end
			end
		when	2
			# 入力階層ファイルはShift_JISコード
			case	out_word_code
			when	'1'
				# 変換後の文字コードはEUCコード
				h_data0 = Kconv::toeuc(hierarcy_data)
				# 改行コードの変換 (windowsでは不要だが、debian側では必要)
				while	h_data0 =~ /\x0d\x0a/
					h_data0.gsub! /\x0d\x0a/, "\x0a"
				end
			when	'2'
				# 変換後の文字コードはシフトJISコード
				h_data0 = hierarcy_data
#				h_data0 = Kconv::tosjis(hierarcy_data)
			end
		when	3
			# 入力階層ファイルはUTF-8コード
			case	out_word_code
			when	'1'
				# 変換後の文字コードはEUCコード
				h_data0 = Uconv.u8toeuc(hierarcy_data)
			when	'2'
				# 変換後の文字コードはシフトJISコード
				h_data0 = Kconv::tosjis(Uconv.u8toeuc(hierarcy_data))
				# 改行コードの変換
				while	h_data0 =~ /[^\x0d]\x0a/
					h_data0.gsub! /([^\x0d])\x0a/, '\1'+"\x0d\x0a"
				end
			end
		when	4
			# 入力階層ファイルはJISコード
			case	out_word_code
			when	'1'
				# 変換後の文字コードはEUCコード
				h_data0 = Kconv::toeuc(hierarcy_data)
			when	'2'
				# 変換後の文字コードはシフトJISコード
				h_data0 = Kconv::tosjis(hierarcy_data)
				# 改行コードの変換
				while	h_data0 =~ /[^\x0d]\x0a/
					h_data0.gsub! /([^\x0d])\x0a/, '\1'+"\x0d\x0a"
				end
			end
		end


		# コメントと行前後の空白を除去
		h_data1 = record_del_comment_space(h_data0)

		# 「=」の前後の空白を除去
		while  /\=[^\S\n]+?/ =~ h_data1
			h_data1.gsub! /\=[^\S\n]+?/ , '='
		end
		while  /\s+?\=/ =~ h_data1
			h_data1.gsub! /\s+?\=/ , '='
		end

		# LineTarget処理
		h_data1 = exec_LineTargetDefinition(h_data1)
		if h_data1 == nil
			# 関数内でエラーが発生した
			raise '「exec_LineTargetDefinition」関数で、エラーが発生しました。(exchange_hierarcy_to_harray)'
			# 例外が発生できない場合を考慮する
			return	nil
		end


		# 階層データリストクラスの生成
		ret_data = HierarcydataList.new


		# 階層情報を階層データリスト形式に変換する

		# 改行単位で配列化
		h_data2 = h_data1.split("\n")

		w_idx1 = 0
		seq_point1 = 0	# 起点位置の初期化

		h_data2.each do |h_data_ex1|

			if h_data_ex1 =~ /^\s*?(\S+?)\s*?\=\s*?(\S+?)\s*?$/
				# $1 = XMLパス
				# $2 = バイト数
				xml_path1 = $1
				seq_byte1 = $2
#				seq_byte1.gsub /^([0-9]*?)[^0-9]??\S*?$/, '\1'	# 書式が変わっても大丈夫なように先手をうつ
				seq_byte1.gsub! /^\s*?([0-9]+?)\s*?,[\S\s]*?$/, '\1'	# 書式が変わっても大丈夫なように先手をうつ
				seq_byte2 = Integer(seq_byte1)

				# 空白項目の場合は、階層データリストには何もセットしない
				if xml_path1 != $nodata_word
					# 階層データリストの該当XMLパスに起点位置とバイト数のセット
					ret_data.put_data_from_xmlpatharray(ret_data.convert_xml_path_to_patharray(xml_path1), seq_point1, seq_byte2, w_idx1)
				end
				# 指定バイト数起点位置をずらす
				seq_point1 += seq_byte2
			else
				raise '階層情報の中に、不正な記述を発見しました。(ほぼ' + String(w_idx1 + 1) + '行目付近)' + "\n" + '[' + h_data_ex1 + ']'
				# 例外が発生できない場合を考慮する
				return	nil
			end
			w_idx1 += 1
		end
		return	[ret_data, w_idx1, seq_point1]
	end


	# ------------------------------------------------------------

	# XMLデータのシーケンシャル情報への変換(階層リストデータ形式)
	#    引数
	# hierarcy_list - 階層リストデータ [IN / 配列(オブジェクト)型]
	# output_mode   - 出力モード [IN / Integer型]
	#                    0 - シーケンシャルファイル出力
	#                    1 - CSVファイル出力
	# out_word_code - 出力文字コード [IN / String型]
	#                    '1' - EUCコード
	#                    '2' - シフトJISコード
	#    戻り値
	# シーケンシャルデータ [OUT / 配列(String)型] ([]の場合、エラー)
	#    [0] - 格納データ (後ろに空白を付けたり、あふれた部分の切り捨てはしていません)
	#    [1] - 起点位置
	#    [2] - 格納バイト数
	#    備考
	# 実行前に、階層情報データを階層リストデータに変換してください。
	# この関数の実行前に「xmldata_setup」メンバー関数を実行してください。
	# 実行後の引数の内容は保証されません
	# 高速化のため、シーケンシャルデータは配列型にしています。
	# ファイル書き込みの際に、順番に書き込んでもらえば通常の文字列を書き込むのと同等になります
	# ただし、空白の場所にnilが入ることがありますので、注意してください。
	#
	def convert_xmldata_to_sequenthdata_main(hierarcy_list, output_mode, out_word_code)


		hirlist_stack = []			# 階層情報リストスタック
									# 子階層に入るたびにスタックに積む
		hirlist_index_stack = []	# 階層情報リストのインデックス値のスタック
									# 子階層に入るたびにスタックに積む
		xmllist_stack = []			# XMLリストスタック
									# 子階層に入るたびにスタックに積む
		xmllist_index_stack = []	# XMLリストのインデックス値のスタック

		now_hirlist = nil			# 現在の対象階層情報リスト
		now_hirlist_index = 0		# 現在の対象階層情報リストのインデックス値
		now_xmllist = nil			# 現在の対象XMLリスト
		now_xmllist_index = 0		# 現在の対象XMLリストのインデックス値

		seq_data = []				# 出力配列データ
									# [0] = 格納データ, [1] = 起点位置, [2] = バイト数


		# 「xmldata_setup」の実行チェック
		if @xmllist == nil
			raise '「xmllist」データメンバーがnilです。「xmldata_setup」が実行されなかったか、エラーが発生していると思われます。'
			# 例外が発生できない場合を考慮する
			return	[]
		end


		now_xmllist = @xmllist			# XMLリストのセット
		now_hirlist = hierarcy_list		# 階層リストのセット


		loop do
			# XMLインデックス値が０の場合、現在のXMLリストにデータ内容があれば、
			# 階層情報リストを参照して、該当領域にデータを書き込む
			if now_xmllist_index == 0
				case	now_xmllist.data
				when	nil, ''
					# 空白からnilなら、何もしない
				else
					if now_hirlist.byte > 0
						# 階層情報で指定されたインデックスの配列に、
						# 内容・起点位置・バイト数をセットする
						seq_data[now_hirlist.seq_num] = [now_xmllist.data, now_hirlist.position, now_hirlist.byte]
					end
				end
			end

# Xml_baselistにデータがあれば、HierarcydataListの指定された領域にデータをセット
#    [格納データ], [起点位置], [バイト数]
# ※上の処理は、インデックスが０の場合に実行する。
#
#
# Xml_baselistの子階層にデータがあれば、HierarcydataListから該当するタグを検索し、
# 子階層を現在のオブジェクトとしてループする。
#
# Xml_basellist子階層にデータがなければ、スタックにオブジェクトがあれば、
# スタックからポップしたものを現在のXMLの階層にする。(インデックスは次にする)
# そして、ループ


			if (now_xmllist.list_value - now_xmllist_index) > 0
				# 子階層がある
				# 階層情報リストから、該当するタグを検索する

				if now_hirlist.hirlist_value > 0
					now_hirlist_index = 0
					for now_hirlist_index in 0..(now_hirlist.hirlist_value - 1) do
						if now_xmllist.xmllist[now_xmllist_index].name == now_hirlist.hirlist[now_hirlist_index].name
							# タグ名が一致した
							# 現在のXMLリスト・階層リストを待避
							xmllist_stack.push now_xmllist
							xmllist_index_stack.push now_xmllist_index
							hirlist_stack.push now_hirlist
							hirlist_index_stack.push now_hirlist_index
							# 現在の対象XMLリスト・階層リストを変更
							now_xmllist = now_xmllist.xmllist[now_xmllist_index]
							now_xmllist_index = 0	# インデックスの初期化
							now_hirlist = now_hirlist.hirlist[now_hirlist_index]
							# for文から抜ける
							break
						else
							if now_hirlist_index == (now_hirlist.hirlist_value - 1)
								# 最後なので、見つからなかった
								now_xmllist_index += 1	# 次のXMLリストに移る
							end
						end
					end

				else
					# 子階層自体がないので、検索しない
					now_xmllist_index = now_xmllist.list_value	# 最後の値にしておく
				end
			else
				# 子階層がない
				now_xmllist = xmllist_stack.pop
				if now_xmllist == nil
					# 親階層もないので、ループから抜ける
					break
				end
				now_xmllist_index = xmllist_index_stack.pop
				now_hirlist = hirlist_stack.pop
#				now_hirlist_index = hirlist_index_stack.pop
				hirlist_index_stack.pop
				now_hirlist_index = 0

				# XMLリストのインデックスを次にする
				now_xmllist_index += 1

			end

		end		# loop do end

		return	seq_data
	end




	# ------------------------------------------------------------

end


# =============================================================================
# =============================================================================
# 関数部




# =============================================================================
# =============================================================================
# メイン処理部
if __FILE__ == $0

	# 初期化処理
	hir_data1 = '' ; hir_data2 = ''
	xml_data1 = ''
	seq_data1 = ''
	hir_list1 = []


	# 階層定義ファイルの読み込み
	open($hir_file, 'r') do |fp_h|
		hir_data1 = fp_h.read
	end


	# XMLファイルの読み込み
	open($xml_file, 'r') do |fp_xml|
		xml_data1 = fp_xml.read
	end


	# XMLリストオブジェクトの確保
	xml_list = Xml_listdata.new


	# XMLデータの取り込み
	case	$lang_conf
	when	'1'
#		$stderr.puts '現在、EUC文字コードでの実行です'
	when	'2'
#		$stderr.puts '現在、シフトJIS文字コードでの実行です'
	else
		raise '予期せぬエラーです'
	end
	xml_list.xmldata_setup(xml_data1, $lang_conf)

	case	$hir_match_mode
	when	0
		# 単純配列形式データ
		# XMLデータをシーケンシャルデータへ変換
		seq_data1 = xml_list.convert_xmldata_to_sequenthdata(hir_data1, $output_mode, $lang_conf)
	when	1
		# 階層データをリスト形式にしたもの
		# 階層情報をリスト構造に変換
		
		hir_list1 = xml_list.exchange_hierarcy_to_hierarcylist(hir_data1, $lang_conf)
		#    戻り値
		# nilか[]の場合 - 階層情報の変換に失敗した
		# nilか[]でない場合
		#  [0] - 階層情報リストデータ [OUT / オブジェクト型]
		#  [1] - 出力件数 [OUT / Numeric型]
		#  [2] - 全体のシーケンシャルデータのバイト数 [OUT / Numeric型]
		# XMLデータをシーケンシャルデータへ変換

		seq_data2 = []
		seq_data2 = xml_list.convert_xmldata_to_sequenthdata_main(hir_list1[0], $output_mode, $lang_conf)

		# 暫定的に、文字列として、格納する
		seq_data1 = []
		seq_data1[0] = ''
		seq_data3 = ''
		seq_data3 = ' ' * hir_list1[2]
		seq_data2.each do |w_ary1|
			# nilの項目をとばす・・・(バグ？)
			if w_ary1 != nil
				seq_data3[w_ary1[1], w_ary1[2]] = w_ary1[0]
			end
		end
		seq_data1[0] = seq_data3
	else
		raise '予期せぬエラーです'
	end


	# シーケンシャルファイルへの書き込み
	open($seq_file, 'w') do |fp_sw|
		seq_data1.each do |w_str1|
			fp_sw.print w_str1
		end
	end


end
# =============================================================================
# =============================================================================
