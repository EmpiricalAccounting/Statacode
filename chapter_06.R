/**************************************
 第6章 記述統計を用いた利益分布アプローチ Stata版
****************************************/
// 作業ディレクトリ（CSVデータを保存したフォルダのパス）を指定
cd "C:\***************\Data_Setvfin\Data_Set"

/// データの読み込み
import delimited ch06_benchmark_analysis.csv, clear

/// 読み込んだデータの確認
// データ型などの確認
describe
// 欠損値やunique valueの数、カテゴリなどの確認
codebook
// データ全体の一覧表示
br

// ROAとWACの変数の作成
gen roa = earnings / lag_total_assets
gen wac = delta_working_capital / lag_total_assets

// ROAのヒストグラムの作成
// ビンは灰色（gs0から16でグレースケールを調整可能）で黒枠，範囲は-0.08から0.08，必ず[0,0.008]を通る
hist roa if inrange(roa, -0.08, 0.08), frequency width(0.008) fcolor(gs12) lcolor(gs1) title("Histogram of ROA") xtitle("ROA") ytitle("Count")

// ROAのヒストグラムで[0,0.008]のビンの色を黒色にする
/***************************************
・ twowayコマンドで複数のヒストグラムを一つにまとめて描画
・複数のグラフは「||」でつなげて記述できる
・改行したい場合は「///」を挿入する
・ifオプションでグラフを0未満、[0,0.008]、0.008より大きい
の３つに分け、それぞれ色を指定
・複数のグラフでX軸の範囲と統一したいときは、
「xscale」オプションで軸の範囲を同じ値に指定する
・複数のグラフを描画すると凡例が表示されるので、
「legend(off)」オプションで凡例を消す
****************************************/
twoway hist roa if inrange(roa, 0, 0.008), frequency width(0.008) xscale(range(-0.08 0.08)) fcolor(black) lcolor(gs1) ///
|| hist roa if roa<0 & roa>=-0.08, frequency width(0.008) xscale(range(-0.08 0.08)) fcolor(gs12) lcolor(gs1) ///
|| hist roa if roa>0.008 & roa<=0.08, frequency width(0.008) xscale(range(-0.08 0.08)) fcolor(gs12) lcolor(gs1) title("Histogram of ROA") xtitle("ROA") ytitle("Count") legend(off)

// ROA昇順でソート
sort roa

// ROAをビン幅に区分する（変数binには区切り点の値が格納される）
egen bin_breaks = cut(roa), at(-0.08(0.008)0.08)
// bin_breaksの値を確認
tab bin_breaks, m
// binの区切り点（binの右端、左端）の値がどちらのbinに含まれるかの挙動がRとStataで異なるので要注意
// 今回はbinの区切り点とroaが完全一致するデータはなかった
br if (bin_breaks == roa)|(bin_breaks == -0.08)|(bin_breaks == 0.08)

// bin_breaksの値に応じたグループ番号binをつくる
egen bin = group(bin_breaks)
br bin bin_breaks

// bin幅ごとに、wacの四分位点とbin区切り点の中央値を作成（stataはna.rm = TRUEは指定不要）
/*********************************************
stataのpctileはRのquantileと四分位点の計算方法が違うので、
値が一致しないセルがある
**********************************************/
bysort bin: egen q_25 = pctile(wac), p(25)
bysort bin: egen q_50 = pctile(wac), p(50)
bysort bin: egen q_75 = pctile(wac), p(75)
duplicates drop bin, force

// 区間の中央値（1行後のbin_breaksの値を足して2で割る
replace bin_breaks = 0.08 in 21
gen bin_mid = (bin_breaks + bin_breaks[_n+1]) / 2

keep bin q_25 q_50 q_75 bin_mid

// ビン幅ごとの四分位点の図表を表示
// 0.004に縦線を引く
twoway line q_25 bin_mid, lcolor(black) lwidth(thin) xscale(range(-0.08 0.08)) ///
|| line q_50 bin_mid, lcolor(black) lwidth(thick) xscale(range(-0.08 0.08)) ///
|| line q_75 bin_mid, lcolor(black) lwidth(vthick) xline(0.004) xscale(range(-0.08 0.08)) ///
legend(label(1 "25%") label(2 "50%") label(3 "75%")) xlabel(-0.08 (0.04) 0.08) ///
xtitle("ROA Bin (median)") ytitle("Warking Capital") title("Quartile of Working Capital per ROA Bin")
