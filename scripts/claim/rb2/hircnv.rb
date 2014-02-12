#!/usr/bin/ruby
# coding : euc-jp
Encoding.default_external = "euc-jp" unless RUBY_VERSION == "1.8.7"


# コンバート処理


# =============================================================================
# =============================================================================
# 直接実行したときの処理
if __FILE__ == $0


	help_flg = 0		# ヘルプ表示フラグ [0 = ヘルプを表示しない, 1 = ヘルプを表示する]

	output_mode = 1		# 出力モード [1 = シンプルモード, 2 = 起点位置付加モード]
	w_file_name = []		# ファイル名の一時的な格納領域


	# 引数のセット処理
	ARGV.each do |w_a1|
		case	w_a1.strip
		when	'--mode1'
			# 出力はシンプルモード
			output_mode = 1
		when	'--mode2'
			# 出力は起点位置付加モード
			output_mode = 2
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
	when	1
		# ファイルの数が少ない
		puts 'コマンドラインの引数にファイル名が指定されていません'
		puts ''
		help_flg = 1
	else
		# ファイル名の指定が２つ以上なので、セットされた内容を渡す
		$soc_file = w_file_name[0]
		$dest_file = w_file_name[1]
	end

	if help_flg == 1
		puts 'hircnv.rb [option] [input file] [output file]'
		puts ''
		puts '  [input file]   コンバート前階層定義ファイル'
		puts '  [output file]  コンバート後階層定義ファイル'
		puts ''
		puts '  [option]'
		puts '    --help ヘルプの表示'
		exit 0
	end


	# 変数確認用の表示処理
	puts 'コンバート前階層定義ファイル = [' + $soc_file + ']'
	puts 'コンバート後階層定義ファイル = [' + $dest_file + ']'



# =============================================================================
	# 別モジュール取り込み処理


	require 'claim2_lib'

end



# =============================================================================
# =============================================================================
# 関数部



# ======================================================================


# =============================================================================
# =============================================================================
# メイン処理部


	# 初期化処理
	hir_data1 = '' ; hir_data2 = '' ; hir_data3 = '' ; hir_data4 = '' ; hir_data5 = ''
	hir_head1 = ''
	sh_type = []


	# 階層定義ファイルの読み込み
	open($soc_file, 'r') do |fp_sh|
		hir_data1 = fp_sh.read
	end

	hir_head1 = hir_data1.sub /\A([\s\S]*?)\n[\s\S]*?\Z/, '\1'
#	puts hir_head1

	# 階層定義ファイル形式の判定
	sh_type = realize_topline(hir_head1)

	# デバッグ用のメッセージ表示
#	puts '=' * 60
#	puts debug_realize_topline_mes 1, sh_type
#	puts '=' * 60

	# 文字コードのみチェック
	case	sh_type[3]
	when	0
		puts '文字コードが未定義のようですが、続行します'
	when	1
		# EUC-JPコード
		puts 'EUC-JPなので、続行します'
#	when	2
#		# Shift_JISコード
#		puts 'Shift_JISなので、続行します'
#	when	3
#		# UTF-8コード
#	when	4
		# JISコード
	else
		raise '階層定義ファイルが対応できない文字コードなので、異常終了させます'
	end

	# 階層定義ファイルのコメントアウト処理
	hir_data2 = record_del_comment_space hir_data1


	# Repeat定義処理
	hir_data3 = repeat_extend_proc(hir_data2)


	# 階層データのbase定義処理
	hir_data4 = basehierarchy_extend_proc(hir_data3)


	# 階層データのLineTarget命令への識別子セット処理
	hir_data5 = linetarget_setmark_proc(hir_data4)


	if output_mode == 2
		# 起点位置付加モードなので、「LineTarget」行を除くXMLパス定義の後ろに起点位置を付加する
		hir_data5 = hierarchy_add_startpoint_proc(hir_data5)
	end


	# 現在、シフトJIS決めうちなので、以下のように先頭にヘッダを付ける
	hir_data5 = '#$ type=hierarchy-execute version=2.0 encoding=EUC-JP' + "\n" + hir_data5
#	hir_data5 = '#$ type=hierarchy-execute version=2.0 encoding=Shift_JIS' + "\n" + hir_data5


	# テスト的に、階層定義ファイルの書き込み
	open($dest_file, 'w') do |fp_dh|
		fp_dh.print hir_data5
	end


# =============================================================================
# =============================================================================
