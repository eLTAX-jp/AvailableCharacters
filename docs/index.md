# eLTAX 利用可能文字一覧

## 利用可能文字一覧の一覧

[利用可能文字一覧(一般)](general.json)

[利用可能文字一覧(口座カナ)](kouza_kana.json)

[利用可能文字一覧(口座漢字)](kouza_kanji.json)

## 一覧ファイルについて

* JSONファイル
* 利用可能文字そのものをキーにしたオブジェクト
* 値の意味 :
  * true : 利用可能文字(かつ表示可能)
  * "Invisible" : 入力可能だが、画面上表示できない文字 (←なんですかそれは)
  * undefined : 利用不可文字

## 使用例

### JavaScript + jQuery

``` javascript
jQuery.getJSON("https://eltax-jp.github.io/AvailableCharacters/general.json", (charset) => {
    charset["A"]; /* => true */
    charset["あ"]; /* => true */
    charset["♪"]; /* => undefined */
    charset["\u3097"]; /* => "Invisible" */
});
```
