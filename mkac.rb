#! /usr/bin/ruby -E:UTF-8
# -*- mode:Ruby; tab-width:4; coding:UTF-8; -*-
# vi:set ft=ruby ts=4 fenc=UTF-8 :
#----------------------------------------------------------------
# eLTAX利用可能文字一覧
#----------------------------------------------------------------

require 'json'

def 利用可能文字一覧_一般
	# 成果物ハッシュ
	charset = {}

	# 入力は利用可能文字一覧のPDFをChromeで開いて全選択して得られるテキスト
	# https://www.eltax.lta.go.jp/documents/00114
	text = File.read("eLTAX 利用可能文字一覧.txt", external_encoding:"UTF-8")

	# 改行で分割
	text = text.split(/\R/)

	# 冒頭の説明文を削除
	while !text.empty? && text[0] !~ /^U/
		text.shift
	end

	# 連結して末尾に改行つける
	text = text.join("\n") + "\n"

	# ゴミ除去
	text.gsub!(/\n[0-9]\n/, "")
	text.gsub!("0 1 2 3 4 5 6 7 8 9 A B C D E F 区分 備考\n", "")
	text.gsub!(/\n- \d+ -\n/, "\n")

	# 「区分」除去
	[
		"基本ラテン文字",
		"ラテン1補助",
		"半角・全角形",
		"基本ギリシャ",
		"キリール",
		"一般句読点",
		"数字の形",
		"矢印",
		"数学記号",
		"囲み英数字",
		"罫線素片",
		"幾何学模様",
		"\nＣＪＫ用の記号及び\n分音記号",
		"平仮名",
		"片仮名",
		"囲みＣＪＫ文字／月",
		"CJK互換漢字",
		"CJK統合漢字",
	].each do |k|
		text.gsub!("#{k}", "")
	end

	# 制御文字を置換
	{
		"(NBSP)" => "\u00a0",
		"(NQSP)" => "\u2000",
		"(MQSP)" => "\u2001",
		"(ENSP)" => "\u2002",
		"(EMSP)" => "\u2003",
		"(3MSP)" => "\u2004",
		"(4MSP)" => "\u2005",
		"(6MSP)" => "\u2006",
		"(FSP)"  => "\u2007",
		"(PSP)"  => "\u2008",
		"(THSP)" => "\u2009",
		"(HSP)"  => "\u200a",
		"(ZWSP)" => "\u200b",
		"[ZWNJ]" => "\u200c",
		"[ZWJ]"  => "\u200d",
		"[LRM]"  => "\u200e",
		"[RLM]"  => "\u200f",
		"\n[LS]" => " \u2028",
		"[PS]"   => "\u2029",
		"[LRE]"  => "\u202a",
		"[RLE]"  => "\u202b",
		"[PDF]"  => "\u202c",
		"[LRO]"  => "\u202d",
		"[RLO]"  => "\u202e",
		"[WJ]"   => "\u2060",
		"[ISS]"  => "\u206a",
		"[ASS]"  => "\u206b",
		"[IAFS]" => "\u206c",
		"[AAFS]" => "\u206d",
		"[NADS]" => "\u206e",
		"[NODS]" => "\u206f",
	}.each do |from, to|
		text.gsub!(from, to)
	end

	# 行ベースで編集
	text = text.split(/\n/) # LS PS が入っているので\Rは使用不可

	# 昇順になっていない(=ゴミ)U+xxxxの行を削除
	code = nil
	text.map! do |aline|
		if aline =~ /^U\+(\h{1,4})/
			c = $1.to_i(16)

			if !code || code < c
				code = c
			else
				aline = ""
			end
		end

		aline
	end

	# 連結して末尾に改行つける
	text = text.join("\n") + "\n"

	# 改行等をいじる
	text.gsub!(/(U\+\h+)\n+/, "\\1 ")
	text.gsub!(/(U\+\h{4})([^ ])/, "\\1 \\2")
	text.gsub!("¬ ®", "¬ \u00ad ®")
	text.gsub!("⁞", "⁞ \u205f")

	# 行末をstrip
	text.gsub!(/\s+\n/, "\n")

	# 文字をいじる & JSON objectに登録
	text = text.split(/\n/).map do |aline|
		aline =~ /^U\+(\h{1,4})/
		code = $1.to_i(16)

		if aline.sub!(/0020は半角スペース$/, "")
			aline[7, 0] = "  "
		elsif aline.sub!(/3000は全角スペース$/, "")
			aline[7, 0] = "　 "
		end

		col = 7
		0.upto(15) do |i|
			if aline[col] && aline[col] == " "
				col += 1
			end
			c = aline[col]
			if c
				truec = (code + i).chr(Encoding::UTF_8)
				if c == truec
					charset[c] = true
				elsif c == "・" # 入力可能ですが、画面上表示できない文字(とは一体!?)
					charset[truec] = "Invisible"
				else
					aline[col, 1] = truec
					# print("#{c} (#{c.ord.to_s(16)}) != #{truec} (#{(code + i).to_s(16)})\n")
				end

				col += 1
			end
		end

		aline
	end

	# 連結して末尾に改行つける
	text = text.join("\n") + "\n"

	# 行末をstrip
	text.gsub!(/\s+\n/, "\n")

	# 文字列長チェック
	# text.split(/\n/).each do |aline|
	# 	if aline.length != 6 + 16*2
	# 		p aline
	# 	end
	# end

	# ソート
	charset = charset.sort.to_h

	File.write("general.txt", text, external_encoding:"UTF-8")
	File.write("docs/general.json", charset.to_json(ascii_only:true), external_encoding:"UTF-8")
end

def 利用可能文字一覧_口座カナ
	# 成果物ハッシュ
	charset = {}

	# 入力はeLTAX HPの「利用者名（カナ）」で使用可能な文字
	# https://www.eltax.lta.go.jp/kyoutsuunouzei/gaiyou/
	text = "０１２３４５６７８９"
	text += "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ"
	text += "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
	text += "゛゜"
	text += "￥，．「」（）－／"
	text += "　"

	# JSON object生成
	text.each_char do |c|
		charset[c] = true
	end

	# ソート
	charset = charset.sort.to_h

	File.write("docs/kouza_kana.json", charset.to_json(ascii_only:true), external_encoding:"UTF-8")
end

# JIS X 0208区点コードに対する文字を得る
def genjischar(ku, tn)
	pic = "あ".encode(Encoding::ISO_2022_JP).force_encoding(Encoding::BINARY)
	abort "Something Wring"  if pic.length != 8

	pic[3] = (ku + 0x20).chr(Encoding::BINARY)
	pic[4] = (tn + 0x20).chr(Encoding::BINARY)

	begin
		pic.force_encoding(Encoding::ISO_2022_JP).encode!(Encoding::UTF_8)
	rescue Encoding::UndefinedConversionError
		return nil
	end

	return pic
end

def 利用可能文字一覧_口座漢字
	# 成果物ハッシュ
	charset = {}

	# 入力はeLTAX HPの「利用者名（漢字）」、「住所」で使用可能な文字
	# https://www.eltax.lta.go.jp/kyoutsuunouzei/gaiyou/
	# 文字セットJIS X 0208-1997の範囲の文字のうち、01区～08区(各種記号、英数字、かな)、16区～47区(JIS第一水準漢字)、48区～84区(JIS第二水準漢字)
	# JIS-X0208-1997 コード表
	# https://www.pcinfo.jpo.go.jp/site/3_support/pdf/zenkaku.pdf
	# https://www.asahi-net.or.jp/~ax2s-kmtn/ref/jisx0208.html
	[1..8, 16..47, 48..84].each do |range|
		range.each do |ku|
			(1..94).each do |tn|
				c = genjischar(ku, tn)
				if c
					charset[c] = true
				end
			end
		end
	end

	# ソート
	charset = charset.sort.to_h

	File.write("docs/kouza_kanji.json", charset.to_json(ascii_only:true), external_encoding:"UTF-8")
end

def main(args)
	利用可能文字一覧_一般

	利用可能文字一覧_口座カナ

	利用可能文字一覧_口座漢字

	return 0
end

exit main(ARGV)
