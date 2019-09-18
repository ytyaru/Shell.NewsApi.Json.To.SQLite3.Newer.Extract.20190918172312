# $1: JSONテキスト, $2: JSONパス
json_extract() { sqlite3 :memory: 'select json_extract(readfile('\'"$1"\''), '\'"$2"\'');'; }
make_insert_stmt() { echo 'insert into news(published,url,title,body) values('\'"$1"\'','\'"$2"\'','\'"$3"\'','\'"$4"\'');'; }
# $1: DB内最新ニュース一意特定値（published,url,title。デリミタ\n）
# $2..3: NewsApi JSON（publishedAt,url）
is_new() {
	local latest_published="`echo "$1" | sed -n 1P`"
	local latest_url="`echo "$1" | sed -n 2P`"
	echo "$latest_published $2 `[[ "$2" < "$latest_published" ]]`"
	[[ "$2" < "$latest_published" ]] && return 0 || [[ "$3" = "$latest_url" ]] && return 0;
	return 1;
}
# $1: url
extract_content() {
	local html="index.html"
	wget -O "$html" "${1}";
	python3 extract_content.py "$html"
}
# $1: NewsApiJSONパス
run() {
	local json_path="$1"
	local insert_sql="insert.sql"
	[ 'ok' != "`json_extract "$json_path" '$.status'`" ] && { echo 'エラー。JSONのstatusがokでない。: '"`json_extract "$json_path" '$.status'`" 1>&2; exit 1; }
	# DB内の最新ニュースを一意特定するデータを取得する（published,url,title）
	local db="news.db"
	local latest_news="`sqlite3 "$db" < 'get_latest.sql'`"
	# SQLファイル内容を空にする（さもなくば連続使用時に前の分と合わせて追記されてしまう）
	: > "$insert_sql"
	local totalResults="`json_extract "$json_path" '$.totalResults'`"
	for idx in $(seq 0 $(expr $totalResults - 1)); do
		# JSONから項目を抽出する
		local published="`json_extract "$json_path" '$.articles['"$idx"'].publishedAt'`"
		local url="`json_extract "$json_path" '$.articles['"$idx"'].url'`"
		is_new "$latest_news" "$published" "$url"; [ $? -eq 0 ] && break;
		local title="`json_extract "$json_path" '$.articles['"$idx"'].title'`"
#		local body="`json_extract "$json_path" '$.articles['"$idx"'].description'`" # とりあえずdescriptionで代用する
		local body="`extract_content "$url"`" # 本文を抽出してプレーンテキスト化したもの
		# totalResultsが多すぎたとき各項目はNULL(空文字)になる。このときは終了する。JSONが正しい限り起こり得ない。
		[ -z "$title" ] && { echo "JSON不正。titleが空。totalResults:$totalResults,idx:$idx" 1>&2; break; }
		# insert文を作る
		make_insert_stmt "$published" "$url" "$title" "$body" >> "$insert_sql"
	done
	sqlite3 "$db" < "$insert_sql"
}
run "$1"

