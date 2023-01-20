"""
Applet: DailyKanji
Summary: Displays a random Kanji
Description: Displays a random Kanji character with translation.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

KANJI_ALIVE_SECRET_KEY = """
AV6+xWcElcF93KogxG+s11bh1XzIRZSLtYHkUd8p3r47B588Bp0UMkbFlo6rUIJXU2p7JwcfctCkxzeWiLf70LDu+ceB6cc+652gRWRWRmj4xhI7/bYgYcigQQR4Q3jUrxjQZy6MIOFS2o01Q36Z+Vt7Uyjg/U6oI8IxIRSx5NGFXW5NQiuVQwVa2XOZC+8RPuFYG1l0QsI=
"""
KANJI_IMAGE_LOOKUP_URL = "https://assets.imgix.net/~text?txt-font=Helvetica%20Neue%20Light&txt-pad=0&txt-color=ff0&txt-size=23&h=32&w=32&txt-align=center%2Cmiddle&txt64="
CACHED_KANJI_NAME = "DailyKanjiCachedItem"
CACHED_KANJI_CHARACTER = "DailyKanjiCachedImage"
KANJI_TTL = 60 * 60 * 2  # updates every 2 hours
kanji_image_list = "国 日 事 人 一 見 本 子 出 年 大 言 学 分 中 記 会 新 月 時 行 気 報 思 上 語 自 者 生 文 明 情 朝 用 書 私 手 間 小 合 方 社 検 目 前 入 関 作 特 何 女 今 体 動 集 発 最 内 投 下 知 地 場 別 話 部 化 告 法 広 来 田 理 物 開 全 説 聞 表 連 無 対 的 高 教 感 心 以 成 名 業 長 家 定 実 山 近 現 後 金 覧 男 画 性 度 数 立 彼 問 二 意 能 個 僕 通 面 回 代 木 利 経 使 車 編 同 平 音 読 少 食 道 世 結 力 楽 真 品 考 公 野 込 所 不 当 取 在 電 愛 外 返 仕 版 際 変 示 親 治 政 島 権 解 他 先 川 三 口 機 風 東 市 付 持 式 加 界 要 信 多 更 活 選 題 屋 論 済 有 身 線 味 著 顔 売 空 続 第 様 海 始 校 英 勝 母 次 点 正 科 京 術 転 録 初 葉 相 約 終 育 住 白 等 声 字 決 登 北 案 天 産 切 都 格 主 県 資 十 元 戦 想 原 指 円 店 死 容 流 過 保 町 足 介 料 安 着 健 調 芸 違 研 古 参 番 館 受 歩 値 歴 笑 引 形 村 然 果 和 究 重 西 議 直 確 強 注 組 良 辞 好 試 可 水 必 送 万 止 帰 典 再 門 写 神 供 紹 運 設 宮 色 推 期 員 映 球 技 落 放 紀 計 予 達 図 支 追 張 去 応 康 夜 民 光 父 工 頭 配 進 験 号 段 囲 宇 由 企 米 細 商 太 置 待 早 右 念 友 断 半 害 帯 像 票 提 覚 件 得 展 悪 室 福 起 乗 制 交 病 各 質 千 構 限 優 残 院 週 詩 星 横 基 規 完 伝 募 総 宙 氏 職 詳 旅 買 位 史 青 将 条 博 単 順 存 突 毎 夫 歌 五 飛 深 誰 座 談 務 婚 演 頼 価 戸 消 評 例 義 常 板 視 左 医 統 坂 団 台 静 申 素 香 域 四 観 陽 首 局 石 戻 認 識 興 呼 類 速 状 製 係 馬 共 護 並 降 君 路 雨 省 求 沢 百 側 土 離 反 曜 種 紙 象 助 頃 飲 望 散 財 判 難 秋 曲 姿 舞 師 疑 境 探 満 純 谷 了 清 程 花 答 火 南 背 駅 器 補 夢 材 差 標 園 両 命 障 禁 黒 建 営 森 根 協 冷 走 折 量 端 居 任 若 造 負 松 橋 区 型 依 街 故 管 抜 司 士 態 押 印 幸 改 独 系 整 息 衛 宅 習 移 犬 株 訳 殺 犯 兄 急 寄 収 休 堂 割 志 兵 忘 赤 打 影 州 階 樹 修 六 客 察 夏 雑 歳 処 緒 絡 罪 照 浮 軽 窓 含 弱 換 準 異 賞 嫌 希 苦 酒 査 刊 欲 池 般 宗 失 未 渡 役 景 列 草 破 針 周 接 城 林 八 販 寝 熱 我 便 証 導 角 具 願 至 遠 片 老 末 責 途 挙 族 専 絵 響 波 絶 茶 暮 盗 授 貴 悩 遊 効 普 杯 王 策 簡 焼 宝 遅 療 鉄 乳 与 算 玉 逃 府 創 働 増 復 余 児 競 抱 装 恋 央 越 久 賀 九 暗 謝 里 眠 非 似 冬 激 極 替 春 薬 痛 留 警 血 巨 払 比 席 備 防 章 脳 費 刷 誤 災 複 触 辺 幅 薄 猫 税 低 布 争 精 誌 髪 節 勢 許 昨 庫 銀 涼 傷 徳 鹿 億 御 除 筋 胸 倒 裁 洋 講 源 領 倉 鳥 札 群 採 妻 裏 刻 派 険 夕 怪 閉 娘 適 互 岩 震 積 占 富 亡 眼 皆 雪 壊 武 捕 模 帳 守 掛 仲 枚 困 避 耳 労 隣 七 測 陸 勉 煙 砂 慣 奥 肉 述 概 勤 恐 射 吹 宿 況 服 課 午 短 鳴 殿 聖 舎 昔 借 従 籍 孝 密 率 築 束 庭 温 担 祭 驚 則 混 昼 超 略 遺 己 矢 腕 婦 牧 巻 届 飯 劇 幕 底 華 衆 竹 哲 伸 脱 泣 趣 腹 筆 昇 敗 候 減 悟 怖 乱 晴 軍 額 就 迷 船 諸 肩 騒 疲 悲 級 港 賃 吸 床 律 永 丸 包 納 爆 党 退 否 羽 植 燃 骨 河 刺 牛 雲 仁 令 描 魚 徒 輪 喜 功 盛 迎 豊 庁 卒 弾 姉 層 固 礼 官 委 寒 腰 怒 毛 紅 操 涙 因 桜 快 給 袋 坊 弁 革 虫 衣 染 荒 幾 童 幼 敵 充 詰 曇 跡 皮 捨 訪 逆 荷 液 練 織 勇 臨 蔵 攻 承 停 農 礎 属 討 抗 弟 季 叫 績 才 沈 券 免 湯 鼻 泉 厚 厳 救 欠 圧 油 看 幹 輸 勧 範 誕 秘 危 漢 易 灯 埋 鏡 句 邪 靴 善 丁 洗 患 汗 泊 枝 倍 署 到 貨 傾 益 箱 黄 寺 栄 頂 欧 仏 仮 狭 均 副 肌 昭 踊 干 喫 奏 齢 詞 宣 閣 損 濃 雇 隊 暇 辛 拡 浴 冗 郵 養 柱 甘 銭 狂 恥 乾 緊 較 汚 臓 歯 郡 誠 菜 冊 岸 旧 晩 航 郷 延 控 凍 憲 暴 緑 焦 柔 祈 机 暖 隅 暑 捜 豆 双 咲 祖 縮 貸 祝 漁 努 賢 贈 舌 塗 浅 卓 抑 缶 湾 序 湖 偶 穴 招 忙 抵 貯 批 即 皇 翌 羊 毒 臣 堅 脈 械 潮 姓 妹 酸 匹 墓 秒 粒 駐 敬 灰 潔 皿 揮 忠 預 珍 沿 畳 憎 奮 唱 輩 挟 畑 縦 渉 拝 賛 糖 伏 奨 訓 貿 芝 湿 貧 刀 俳 硬 飼 氷 糸 棒 鋭 弓 拾 飽 軒 軟 粉 往 塔 封 掃 炭 冒 泳 零 磁 鈍 泥 盟 誇 磨 鉱 胃 偉 兆 掘 朗 垂 絹 偏 筒 旗 菓 稲 征 乏 蒸 脂 尊 溶 膚 枯 沸 帽 恩 寮 符 寸 郊 肥 孫 豚 塩 燥 濯 肺 熟 辱 滴 伺 卵 梅 舟 麦 芽 敢 巣 穫 銅 班"

def main(config):
    kanji_data = cache.get(CACHED_KANJI_NAME)
    kanji_image_src = cache.get(CACHED_KANJI_CHARACTER)
    kanji_alive_key = secret.decrypt(KANJI_ALIVE_SECRET_KEY) or config.get("dev_api_key")

    if kanji_data == None:
        #pick a random kanji from our data of kanji and image data
        random_kanji = get_random_kanji(kanji_image_list)

        #use the api to get the meaning, and the two readings (onyomi and kunyomi)
        kanji_data = get_kanji_information(random_kanji, kanji_alive_key)

        #we really don't need but one section of this, so we'll just use and store this part in cache
        #hey why not do something if its a little more efficient, even if it will never be noticed by anyone
        kanji_data = kanji_data["kanji"]

        #Create Image for the selected Kanji
        kanji_image_url = KANJI_IMAGE_LOOKUP_URL + base64.encode(kanji_data["character"])
        kanji_image_src = http.get(kanji_image_url).body()

        #lets cache this so there is only one call per TTL across all tidbyt's
        cache.set(CACHED_KANJI_NAME, json.encode(kanji_data), ttl_seconds = KANJI_TTL)
        cache.set(CACHED_KANJI_CHARACTER, kanji_image_src, ttl_seconds = KANJI_TTL)
    else:
        #We have the data in cache, let's use it
        print("Getting from cache")
        kanji_data = json.decode(kanji_data)
        kanji_image_src = kanji_image_src

    #Display 3 rows of Text
    #row1 will store the meaning of the character in English
    row1 = kanji_data["meaning"]["english"]

    #Japanese language was originally spoken only, the Chinese introduced written characters
    #So Japanese learned these characters and pronounced them like the Chinese did
    #But they also would associate these chinese written words with the Japanese spoken language

    #row2 will store the onyomi or native Chinese pronunciation if it's used for this kanji
    row2 = kanji_data["onyomi"]["romaji"]
    if row2 == "n/a":
        row2 = ""

    #row3 will store the kunyomi or Japanese pronunciation it it's used for this kanji
    row3 = kanji_data["kunyomi"]["romaji"]
    if row3 == "n/a":
        row3 = ""

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Column(
                            children = [
                                render.Image(src = kanji_image_src),
                            ],
                        ),
                        render.Column(
                            children = [
                                render.Marquee(
                                    width = 32,
                                    child = render.Text(row1, color = "#0a60a2", font = "6x13"),
                                ),
                                render.Marquee(
                                    width = 32,
                                    child = render.Text(row2, color = "#f4a306"),
                                ),
                                render.Marquee(
                                    width = 32,
                                    child = render.Text(row3, color = "#e77c05"),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_random_kanji(kanji_image_list):
    kanji_images = kanji_image_list.split(" ")
    random_number = random(0, len(kanji_images))
    i = 0
    for item in kanji_images:
        if random_number == i:
            return item
        i = i + 1

    # Should never get here.
    return kanji_images[0]

def random(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max - min) + min)

def display_kanji_with_image_url(individual_kanji, kanji_alive_key):
    i = 0
    for kanjicharacter in individual_kanji:
        i = i + 1
        url = "https://kanjiapi.dev/v1/kanji/%s" % kanjicharacter
        kanji_http = http.get(url)
        kanji_data = kanji_http.json()
        print(i)
        kanji_image_json = get_kanji_information(kanji_data["kanji"], kanji_alive_key)
        if "kanji" not in kanji_image_json:
            print("%s %s" % (kanjicharacter, i))

#unused for now, but if we want to refactor later and get the image
#and convert, we could do that instead of storing all that base64 stuff in the file here
def get_kanji_image(image_url):
    return http.get(image_url).body()

#Using the kanjialive api to get information on a particular kanji character
def get_kanji_information(selected_kanji, kanji_alive_key):
    res = http.get(
        url = "https://kanjialive-api.p.rapidapi.com/api/public/kanji/%s" % selected_kanji,
        headers = {
            "X-RapidAPI-Host": "kanjialive-api.p.rapidapi.com",
            "X-RapidAPI-Key": kanji_alive_key,
        },
    )

    if res.status_code == 200:
        #print("Received Data from Fitbit!")
        return res.json()
    else:
        print("Error")
        return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
