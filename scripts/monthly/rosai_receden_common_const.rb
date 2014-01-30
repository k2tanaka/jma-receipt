#!/usr/bin/ruby

class Receden_common_const

  H250531 = "20130531"

  N = NUMERIC      = 0
  A = ALPHANUMERIC = 1
  K = KANJI        = 2
  T = TEXT         = 3 #(A or K)
  J = KATAKANA     = 4

  #-------------------------------------------------------------------------------
  #   Record Definition
  #-------------------------------------------------------------------------------
  IRrecord=["レコード識別情報"          ,"RECID"    ,A, 2 ,true  ,true],
           ["予備１"                    ,"YOBI01"   ,N, 1 ,false ,false],
           ["都道府県"                  ,"PREFNUM"  ,N, 2 ,true  ,true],
           ["点数表"                    ,"TNSNUM"   ,N, 1 ,true  ,true],
           ["医療機関コード"            ,"HOSPCD"   ,N, 7 ,true  ,true],
           ["予備２"                    ,"YOBI02"   ,N, 2 ,false ,false],
           ["医療機関名称"              ,"HOSPNAME" ,K,40 ,false ,true],
           ["請求年月"                  ,"SKYYM"    ,N, 5 ,true  ,true],
           ["マルチボリューム識別情報"  ,"MVOLID"   ,N, 2 ,true  ,true],
           ["電話番号"                  ,"TEL"      ,A,15 ,false ,false]

  RErecord=["レコード識別情報"                  ,"RECID"                  ,A, 2,true ,true],
           ["レセプト番号"                      ,"RECENUM"                ,N, 6,false,true],
           ["予備１"                            ,"YOBI01"                 ,N, 4,false,false],
           ["予備２"                            ,"YOBI02"                 ,N, 5,false,false],
           ["労働者の氏名"                      ,"NAME"                   ,T,40,false,true],
           ["男女区分"                          ,"SEX"                    ,N, 1,true ,true],
           ["生年月日"                          ,"BIRTHDAY"               ,N, 7,true ,true],
           ["予備３"                            ,"YOBI03"                 ,N, 3,false,false],
           ["入院年月日"                        ,"NYUINYMD"               ,N, 7,false,false],
           ["病棟区分"                          ,"BTUKBN"                 ,A, 8,false,false],
           ["予備４"                            ,"YOBI04"                 ,N, 1,false,false],
           ["予備５"                            ,"YOBI05"                 ,A,10,false,false],
           ["病床数"                            ,"BEDSU"                  ,N, 4,false,false],
           ["カルテ番号等"                      ,"PTNUM"                  ,A,20,false,false],
           ["予備６"                            ,"YOBI06"                 ,N, 2,false,false],
           ["予備７"                            ,"YOBI07"                 ,N, 1,false,false],
           ["予備８"                            ,"YOBI08"                 ,N, 1,false,false],
           ["予備９"                            ,"YOBI09"                 ,N, 2,false,false],
           ["電算処理受付番号"                  ,"SELNUM"                 ,A,20,false,false],
           ["記録条件仕様年月情報"              ,"RECYM"                  ,N, 5,false,false],
           ["請求情報"                          ,"SKYINF"                 ,A,40,false,false],
           ["診療科１診療科名"                  ,"SRYKA1_CD"              ,N, 2,false,false],
           ["診療科１組み合わせ名称人体の部位等","SRYKA1_BUI"             ,N, 3,false,false],
           ["診療科１組み合わせ名称性別等"      ,"SRYKA1_SEX"             ,N, 3,false,false],
           ["診療科１組み合わせ名称医学的処置"  ,"SRYKA1_SHOCHI"          ,N, 3,false,false],
           ["診療科１組み合わせ名称特定疾病"    ,"SRYKA1_TOKSIPPEI"       ,N, 3,false,false],
           ["診療科２診療科名"                  ,"SRYKA2_CD"              ,N, 2,false,false],
           ["診療科２組み合わせ名称人体の部位等","SRYKA2_BUI"             ,N, 3,false,false],
           ["診療科２組み合わせ名称性別等"      ,"SRYKA2_SEX"             ,N, 3,false,false],
           ["診療科２組み合わせ名称医学的処置"  ,"SRYKA2_SHOCHI"          ,N, 3,false,false],
           ["診療科２組み合わせ名称特定疾病"    ,"SRYKA2_TOKSIPPEI"       ,N, 3,false,false],
           ["診療科３診療科名"                  ,"SRYKA3_CD"              ,N, 2,false,false],
           ["診療科３組み合わせ名称人体の部位等","SRYKA3_BUI"             ,N, 3,false,false],
           ["診療科３組み合わせ名称性別等"      ,"SRYKA3_SEX"             ,N, 3,false,false],
           ["診療科３組み合わせ名称医学的処置"  ,"SRYKA3_SHOCHI"          ,N, 3,false,false],
           ["診療科３組み合わせ名称特定疾病"    ,"SRYKA3_TOKSIPPEI"       ,N, 3,false,false]




  RRrecord=["レコード識別情報"            ,"RECID"         ,A,  2,true ,true],
           ["回数（同一傷病について）"    ,"KAISU"         ,N,  3,false,false],
           ["業務災害・通勤災害の区分"    ,"SAIGAIKBN"     ,N,  1,true ,true],
           ["帳票種別"                    ,"FORMSBT"       ,N,  1,true ,true],
           ["年金証書番号"                ,"CHOKINUM"      ,N,  9,false,false],
           ["労働保険番号"                ,"TANKINUM"      ,N, 14,false,false],
           ["傷病年月日"                  ,"SHOBYOYMD"     ,N,  7,false,false],
           ["新継再別"                    ,"SHINKEIKBN"    ,N,  1,true ,true],
           ["転帰事由"                    ,"TENKIKBN"      ,N,  1,true ,true],
           ["療養期間―初日"              ,"RYOSTYMD"      ,N,  7,true ,true],
           ["療養期間―末日"              ,"RYOEDYMD"      ,N,  7,true ,true],
           ["診療実日数"                  ,"JNISSU"        ,N,  3,false,true],
           ["労働者の氏名（カナ）"        ,"KANANAME"      ,J, 40,false,true],
           ["事業の名称"                  ,"INFO"          ,K, 40,false,false],
           ["事業場の所在地"              ,"LOCATION"      ,K, 80,false,false],
           ["傷病の経過"                  ,"KEIKA"         ,K,100,false,true],
           ["小計点数"                    ,"TENSU"         ,N,  8,false,true],
           ["小計点数金額換算【イ】"      ,"TENSU_KANZAN"  ,N,  9,false,true],
           ["小計金額【ロ】"              ,"KINGAKU"       ,N,  9,false,true],
           ["食事療養合計回数"            ,"SKJKAISU"      ,N,  2,false,false],
           ["食事療養合計金額【ハ】"      ,"SKJKINGAKU"    ,N,  8,false,false],
           ["合計額【イ)＋【ロ】＋【ハ】" ,"GOKEI"         ,N,  9,false,true]

  SYrecord=["レコード識別情報"            ,"RECID"         ,A,  2,true ,true ],
           ["傷病名コード"                ,"BYOMEICD"      ,N,  7,true ,true ],
           ["診療開始日"                  ,"SRYYMD"        ,N,  7,true ,true ],
           ["予備１"                      ,"YOBI01"        ,N,  1,false,false],
           ["修飾語コード"                ,"MODCD"         ,A, 80,false,false],
           ["傷病名称"                    ,"BYOMEI"        ,K, 40,false,false],
           ["主傷病"                      ,"SYUBYO"        ,N,  2,false,false],
           ["補足コメント"                ,"HSKCOM"        ,K, 40,false,false]

  RIrecord=["レコード識別情報"            ,"RECID"            ,A,   2,true ,true ],
           ["診療識別"                    ,"SRYKBN"           ,N,   2,false,false],
           ["診療行為コード"              ,"SRYCD"            ,N,   9,true ,true ],
           ["数量データ"                  ,"SURYO"            ,N,   8,false,false],
           ["点数"                        ,"TEN"              ,N,   7,false,false],
           ["金額"                        ,"KINGAKU"          ,N,   7,false,false],
           ["回数"                        ,"KAISU"            ,N,   3,false,true],
           ["コメントコード１"            ,"COMCD1"           ,N,   9,false,false],
           ["コメント文字データ１"        ,"COMMENT1"         ,K, 100,false,false],
           ["コメントコード２"            ,"COMCD2"           ,N,   9,false,false],
           ["コメント文字データ２"        ,"COMMENT2"         ,K, 100,false,false],
           ["コメントコード３"            ,"COMCD3"           ,N,   9,false,false],
           ["コメント文字データ３"        ,"COMMENT3"         ,K, 100,false,false],
           ["１日の情報"                  ,"DAY01"            ,N,   3,false,false],
           ["２日の情報"                  ,"DAY02"            ,N,   3,false,false],
           ["３日の情報"                  ,"DAY03"            ,N,   3,false,false],
           ["４日の情報"                  ,"DAY04"            ,N,   3,false,false],
           ["５日の情報"                  ,"DAY05"            ,N,   3,false,false],
           ["６日の情報"                  ,"DAY06"            ,N,   3,false,false],
           ["７日の情報"                  ,"DAY07"            ,N,   3,false,false],
           ["８日の情報"                  ,"DAY08"            ,N,   3,false,false],
           ["９日の情報"                  ,"DAY09"            ,N,   3,false,false],
           ["１０日の情報"                ,"DAY10"            ,N,   3,false,false],
           ["１１日の情報"                ,"DAY11"            ,N,   3,false,false],
           ["１２日の情報"                ,"DAY12"            ,N,   3,false,false],
           ["１３日の情報"                ,"DAY13"            ,N,   3,false,false],
           ["１４日の情報"                ,"DAY14"            ,N,   3,false,false],
           ["１５日の情報"                ,"DAY15"            ,N,   3,false,false],
           ["１６日の情報"                ,"DAY16"            ,N,   3,false,false],
           ["１７日の情報"                ,"DAY17"            ,N,   3,false,false],
           ["１８日の情報"                ,"DAY18"            ,N,   3,false,false],
           ["１９日の情報"                ,"DAY19"            ,N,   3,false,false],
           ["２０日の情報"                ,"DAY20"            ,N,   3,false,false],
           ["２１日の情報"                ,"DAY21"            ,N,   3,false,false],
           ["２２日の情報"                ,"DAY22"            ,N,   3,false,false],
           ["２３日の情報"                ,"DAY23"            ,N,   3,false,false],
           ["２４日の情報"                ,"DAY24"            ,N,   3,false,false],
           ["２５日の情報"                ,"DAY25"            ,N,   3,false,false],
           ["２６日の情報"                ,"DAY26"            ,N,   3,false,false],
           ["２７日の情報"                ,"DAY27"            ,N,   3,false,false],
           ["２８日の情報"                ,"DAY28"            ,N,   3,false,false],
           ["２９日の情報"                ,"DAY29"            ,N,   3,false,false],
           ["３０日の情報"                ,"DAY30"            ,N,   3,false,false],
           ["３１日の情報"                ,"DAY31"            ,N,   3,false,false]


  IYrecord=["レコード識別情報"            ,"RECID"            ,A,  2,true ,true],
           ["診療識別"                    ,"SRYKBN"           ,N,  2,false,false],
           ["予備１"                      ,"YOBI01"           ,A,  1,false,false],
           ["医薬品コード"                ,"SRYCD"            ,N,  9,true ,true],
           ["使用量"                      ,"SURYO"            ,A, 11,false,false],
           ["点数"                        ,"TEN"              ,N,  7,false,false],
           ["回数"                        ,"KAISU"            ,N,  3,false,true],
           ["コメントコード１"            ,"COMCD1"           ,N,  9,false,false],
           ["コメント文字データ１"        ,"COMMENT1"         ,K,100,false,false],
           ["コメントコード２"            ,"COMCD2"           ,N,  9,false,false],
           ["コメント文字データ２"        ,"COMMENT2"         ,K,100,false,false],
           ["コメントコード３"            ,"COMCD3"           ,N,  9,false,false],
           ["コメント文字データ３"        ,"COMMENT3"         ,K,100,false,false],
           ["１日の情報"                  ,"DAY01"            ,N,  3,false,false],
           ["２日の情報"                  ,"DAY02"            ,N,  3,false,false],
           ["３日の情報"                  ,"DAY03"            ,N,  3,false,false],
           ["４日の情報"                  ,"DAY04"            ,N,  3,false,false],
           ["５日の情報"                  ,"DAY05"            ,N,  3,false,false],
           ["６日の情報"                  ,"DAY06"            ,N,  3,false,false],
           ["７日の情報"                  ,"DAY07"            ,N,  3,false,false],
           ["８日の情報"                  ,"DAY08"            ,N,  3,false,false],
           ["９日の情報"                  ,"DAY09"            ,N,  3,false,false],
           ["１０日の情報"                ,"DAY10"            ,N,  3,false,false],
           ["１１日の情報"                ,"DAY11"            ,N,  3,false,false],
           ["１２日の情報"                ,"DAY12"            ,N,  3,false,false],
           ["１３日の情報"                ,"DAY13"            ,N,  3,false,false],
           ["１４日の情報"                ,"DAY14"            ,N,  3,false,false],
           ["１５日の情報"                ,"DAY15"            ,N,  3,false,false],
           ["１６日の情報"                ,"DAY16"            ,N,  3,false,false],
           ["１７日の情報"                ,"DAY17"            ,N,  3,false,false],
           ["１８日の情報"                ,"DAY18"            ,N,  3,false,false],
           ["１９日の情報"                ,"DAY19"            ,N,  3,false,false],
           ["２０日の情報"                ,"DAY20"            ,N,  3,false,false],
           ["２１日の情報"                ,"DAY21"            ,N,  3,false,false],
           ["２２日の情報"                ,"DAY22"            ,N,  3,false,false],
           ["２３日の情報"                ,"DAY23"            ,N,  3,false,false],
           ["２４日の情報"                ,"DAY24"            ,N,  3,false,false],
           ["２５日の情報"                ,"DAY25"            ,N,  3,false,false],
           ["２６日の情報"                ,"DAY26"            ,N,  3,false,false],
           ["２７日の情報"                ,"DAY27"            ,N,  3,false,false],
           ["２８日の情報"                ,"DAY28"            ,N,  3,false,false],
           ["２９日の情報"                ,"DAY29"            ,N,  3,false,false],
           ["３０日の情報"                ,"DAY30"            ,N,  3,false,false],
           ["３１日の情報"                ,"DAY31"            ,N,  3,false,false]

  TOrecord=["レコード識別情報"            ,"RECID"            ,A,  2,true ,true ],
           ["診療識別"                    ,"SRYKBN"           ,N,  2,false,false],
           ["予備１"                      ,"YOBI01"           ,A,  1,false,false],
           ["特定器材コード"              ,"SRYCD"            ,N,  9,true ,true ],
           ["使用量"                      ,"SURYO"            ,A,  9,false,false],
           ["点数"                        ,"TEN"              ,N,  7,false,false],
           ["回数"                        ,"KAISU"            ,N,  3,false,true],
           ["単位コード"                  ,"TANICD"           ,N,  3,false,false],
           ["単価"                        ,"TANKA"            ,A, 11,false,false],
           ["特定器材名称"                ,"NAME"             ,K, 40,false,false],
           ["商品名及び規格又はサイズ"    ,"INFO"             ,K,300,false,false],
           ["コメントコード１"            ,"COMCD1"           ,N,  9,false,false],
           ["コメント文字データ１"        ,"COMMENT1"         ,K,100,false,false],
           ["コメントコード２"            ,"COMCD2"           ,N,  9,false,false],
           ["コメント文字データ２"        ,"COMMENT2"         ,K,100,false,false],
           ["コメントコード３"            ,"COMCD3"           ,N,  9,false,false],
           ["コメント文字データ３"        ,"COMMENT3"         ,K,100,false,false],
           ["１日の情報"                  ,"DAY01"            ,N,  3,false,false],
           ["２日の情報"                  ,"DAY02"            ,N,  3,false,false],
           ["３日の情報"                  ,"DAY03"            ,N,  3,false,false],
           ["４日の情報"                  ,"DAY04"            ,N,  3,false,false],
           ["５日の情報"                  ,"DAY05"            ,N,  3,false,false],
           ["６日の情報"                  ,"DAY06"            ,N,  3,false,false],
           ["７日の情報"                  ,"DAY07"            ,N,  3,false,false],
           ["８日の情報"                  ,"DAY08"            ,N,  3,false,false],
           ["９日の情報"                  ,"DAY09"            ,N,  3,false,false],
           ["１０日の情報"                ,"DAY10"            ,N,  3,false,false],
           ["１１日の情報"                ,"DAY11"            ,N,  3,false,false],
           ["１２日の情報"                ,"DAY12"            ,N,  3,false,false],
           ["１３日の情報"                ,"DAY13"            ,N,  3,false,false],
           ["１４日の情報"                ,"DAY14"            ,N,  3,false,false],
           ["１５日の情報"                ,"DAY15"            ,N,  3,false,false],
           ["１６日の情報"                ,"DAY16"            ,N,  3,false,false],
           ["１７日の情報"                ,"DAY17"            ,N,  3,false,false],
           ["１８日の情報"                ,"DAY18"            ,N,  3,false,false],
           ["１９日の情報"                ,"DAY19"            ,N,  3,false,false],
           ["２０日の情報"                ,"DAY20"            ,N,  3,false,false],
           ["２１日の情報"                ,"DAY21"            ,N,  3,false,false],
           ["２２日の情報"                ,"DAY22"            ,N,  3,false,false],
           ["２３日の情報"                ,"DAY23"            ,N,  3,false,false],
           ["２４日の情報"                ,"DAY24"            ,N,  3,false,false],
           ["２５日の情報"                ,"DAY25"            ,N,  3,false,false],
           ["２６日の情報"                ,"DAY26"            ,N,  3,false,false],
           ["２７日の情報"                ,"DAY27"            ,N,  3,false,false],
           ["２８日の情報"                ,"DAY28"            ,N,  3,false,false],
           ["２９日の情報"                ,"DAY29"            ,N,  3,false,false],
           ["３０日の情報"                ,"DAY30"            ,N,  3,false,false],
           ["３１日の情報"                ,"DAY31"            ,N,  3,false,false]

  COrecord=["レコード識別情報"            ,"RECID"            ,A,  2,true ,true  ],
           ["診療識別"                    ,"SRYKBN"           ,N,  2,false,false ],
           ["予備１"                      ,"YOBI1"            ,A,  1,false,false ],
           ["コメントコード"              ,"SRYCD"            ,N,  9,true ,true  ],
           ["文字データ"                  ,"DATA"             ,K, 76,false,false ]

  SJrecord=["レコード識別情報"            ,"RECID"            ,A,   2,true ,true ],
           ["症状詳記区分"                ,"SJKBN"            ,N,   2,false,false ],
           ["症状詳記データ"              ,"DATA"             ,K,2400,false,false]

  RSrecord=["レコード識別情報"            ,"RECID"            ,A, 2,true ,true ],
           ["病院・診療所の区分"          ,"HOSPKBN"          ,A, 1,true ,true],
           ["請求書提出年月日"            ,"SKYYMD"           ,A, 7,true ,true],
           ["都道府県労働局コード"        ,"PREFCD"          ,N, 2,false,false],
           ["労働基準監督署コード"        ,"OFFICECD"        ,N, 2,false,false],
           ["指定病院等の番号"            ,"HOSPCD"           ,N, 7,true ,true ],
           ["郵便番号"                    ,"ZIPCD"            ,N, 7,false,false],
           ["医療機関所在地"              ,"LOCATION"         ,K,80,false,true ],
           ["医療機関責任者氏名"          ,"NAME"             ,K,40,false,true ],
           ["労災診療費単価"              ,"TANKA"            ,N, 4,true ,true ],
           ["請求金額"                    ,"SKYMONEY"         ,N, 9,false,true ],
           ["内訳書添付枚数"              ,"MAISU"            ,N, 3,false,false],
           ["マルチボリューム識別情報"    ,"MVOLID"           ,N, 2,true ,true ]

  ETCrecord=["レコード識別情報"           ,"RECID"       ,A,2  ,false,false],
            ["項目０１"                   ,"DATA01"      ,T,500,false,false],
            ["項目０２"                   ,"DATA02"      ,T,500,false,false],
            ["項目０３"                   ,"DATA03"      ,T,500,false,false],
            ["項目０４"                   ,"DATA04"      ,T,500,false,false],
            ["項目０５"                   ,"DATA05"      ,T,500,false,false],
            ["項目０６"                   ,"DATA06"      ,T,500,false,false],
            ["項目０７"                   ,"DATA07"      ,T,500,false,false],
            ["項目０８"                   ,"DATA08"      ,T,500,false,false],
            ["項目０９"                   ,"DATA09"      ,T,500,false,false],
            ["項目１０"                   ,"DATA10"      ,T,500,false,false],
            ["項目１１"                   ,"DATA11"      ,T,500,false,false],
            ["項目１２"                   ,"DATA12"      ,T,500,false,false],
            ["項目１３"                   ,"DATA13"      ,T,500,false,false],
            ["項目１４"                   ,"DATA14"      ,T,500,false,false],
            ["項目１５"                   ,"DATA15"      ,T,500,false,false],
            ["項目１６"                   ,"DATA16"      ,T,500,false,false],
            ["項目１７"                   ,"DATA17"      ,T,500,false,false],
            ["項目１８"                   ,"DATA18"      ,T,500,false,false],
            ["項目１９"                   ,"DATA19"      ,T,500,false,false],
            ["項目２０"                   ,"DATA20"      ,T,500,false,false],
            ["項目２１"                   ,"DATA21"      ,T,500,false,false],
            ["項目２２"                   ,"DATA22"      ,T,500,false,false],
            ["項目２３"                   ,"DATA23"      ,T,500,false,false],
            ["項目２４"                   ,"DATA24"      ,T,500,false,false],
            ["項目２５"                   ,"DATA25"      ,T,500,false,false],
            ["項目２６"                   ,"DATA26"      ,T,500,false,false],
            ["項目２７"                   ,"DATA27"      ,T,500,false,false],
            ["項目２８"                   ,"DATA28"      ,T,500,false,false],
            ["項目２９"                   ,"DATA29"      ,T,500,false,false],
            ["項目３０"                   ,"DATA30"      ,T,500,false,false],
            ["項目３１"                   ,"DATA31"      ,T,500,false,false],
            ["項目３２"                   ,"DATA32"      ,T,500,false,false],
            ["項目３３"                   ,"DATA33"      ,T,500,false,false],
            ["項目３４"                   ,"DATA34"      ,T,500,false,false],
            ["項目３５"                   ,"DATA35"      ,T,500,false,false],
            ["項目３６"                   ,"DATA36"      ,T,500,false,false],
            ["項目３７"                   ,"DATA37"      ,T,500,false,false],
            ["項目３８"                   ,"DATA38"      ,T,500,false,false],
            ["項目３９"                   ,"DATA39"      ,T,500,false,false],
            ["項目４０"                   ,"DATA40"      ,T,500,false,false],
            ["項目４１"                   ,"DATA41"      ,T,500,false,false],
            ["項目４２"                   ,"DATA42"      ,T,500,false,false],
            ["項目４３"                   ,"DATA43"      ,T,500,false,false],
            ["項目４４"                   ,"DATA44"      ,T,500,false,false],
            ["項目４５"                   ,"DATA45"      ,T,500,false,false],
            ["項目４６"                   ,"DATA46"      ,T,500,false,false],
            ["項目４７"                   ,"DATA47"      ,T,500,false,false],
            ["項目４８"                   ,"DATA48"      ,T,500,false,false],
            ["項目４９"                   ,"DATA49"      ,T,500,false,false],
            ["項目５０"                   ,"DATA50"      ,T,500,false,false],
            ["項目５１"                   ,"DATA51"      ,T,500,false,false],
            ["項目５２"                   ,"DATA52"      ,T,500,false,false],
            ["項目５３"                   ,"DATA53"      ,T,500,false,false],
            ["項目５４"                   ,"DATA54"      ,T,500,false,false],
            ["項目５５"                   ,"DATA55"      ,T,500,false,false],
            ["項目５６"                   ,"DATA56"      ,T,500,false,false],
            ["項目５７"                   ,"DATA57"      ,T,500,false,false],
            ["項目５８"                   ,"DATA58"      ,T,500,false,false],
            ["項目５９"                   ,"DATA59"      ,T,500,false,false],
            ["項目６０"                   ,"DATA60"      ,T,500,false,false],
            ["項目６１"                   ,"DATA61"      ,T,500,false,false],
            ["項目６２"                   ,"DATA62"      ,T,500,false,false],
            ["項目６３"                   ,"DATA63"      ,T,500,false,false],
            ["項目６４"                   ,"DATA64"      ,T,500,false,false],
            ["項目６５"                   ,"DATA65"      ,T,500,false,false],
            ["項目６６"                   ,"DATA66"      ,T,500,false,false],
            ["項目６７"                   ,"DATA67"      ,T,500,false,false],
            ["項目６８"                   ,"DATA68"      ,T,500,false,false],
            ["項目６９"                   ,"DATA69"      ,T,500,false,false],
            ["項目７０"                   ,"DATA70"      ,T,500,false,false],
            ["項目７１"                   ,"DATA71"      ,T,500,false,false],
            ["項目７２"                   ,"DATA72"      ,T,500,false,false],
            ["項目７３"                   ,"DATA73"      ,T,500,false,false],
            ["項目７４"                   ,"DATA74"      ,T,500,false,false],
            ["項目７５"                   ,"DATA75"      ,T,500,false,false],
            ["項目７６"                   ,"DATA76"      ,T,500,false,false],
            ["項目７７"                   ,"DATA77"      ,T,500,false,false],
            ["項目７８"                   ,"DATA78"      ,T,500,false,false],
            ["項目７９"                   ,"DATA79"      ,T,500,false,false],
            ["項目８０"                   ,"DATA80"      ,T,500,false,false],
            ["項目８１"                   ,"DATA81"      ,T,500,false,false],
            ["項目８２"                   ,"DATA82"      ,T,500,false,false],
            ["項目８３"                   ,"DATA83"      ,T,500,false,false],
            ["項目８４"                   ,"DATA84"      ,T,500,false,false],
            ["項目８５"                   ,"DATA85"      ,T,500,false,false],
            ["項目８６"                   ,"DATA86"      ,T,500,false,false],
            ["項目８７"                   ,"DATA87"      ,T,500,false,false],
            ["項目８８"                   ,"DATA88"      ,T,500,false,false],
            ["項目８９"                   ,"DATA89"      ,T,500,false,false],
            ["項目９０"                   ,"DATA90"      ,T,500,false,false],
            ["項目９１"                   ,"DATA91"      ,T,500,false,false],
            ["項目９２"                   ,"DATA92"      ,T,500,false,false],
            ["項目９３"                   ,"DATA93"      ,T,500,false,false],
            ["項目９４"                   ,"DATA94"      ,T,500,false,false],
            ["項目９５"                   ,"DATA95"      ,T,500,false,false],
            ["項目９６"                   ,"DATA96"      ,T,500,false,false],
            ["項目９７"                   ,"DATA97"      ,T,500,false,false],
            ["項目９８"                   ,"DATA98"      ,T,500,false,false],
            ["項目９９"                   ,"DATA99"      ,T,500,false,false]


  NYUGAI="0"
  NYUIN="1"
  GAIRAI="2"

  TANKI="1"
  CHOKI="2"

  SJKBN = { "01" => "01",
    "02" => "02",
    "03" => "03",
    "04" => "04",
    "05" => "05",
    "06" => "06",
    "07" => "07",
    "50" => "50",
    "51" => "51",
    "52" => "52",
  "90" => "90" }

  PREFCD={"HOKKAIDO"  => "01",
          "AOMORI"    => "02",
          "IWATE"     => "03",
          "MIYAGI"    => "04",
          "AKITA"     => "05",
          "YAMAGATA"  => "06",
          "FUKUSHIMA" => "07",
          "IBARAKI"   => "08",
          "TOCHIGI"   => "09",
          "GUNMA"     => "10",
          "SAITAMA"   => "11",
          "CHIBA"     => "12",
          "TOKYO"     => "13",
          "KANAGAWA"  => "14",
          "NIIGATA"   => "15",
          "TOYAMA"    => "16",
          "ISHIKAWA"  => "17",
          "FUKUI"     => "18",
          "YAMANASHI" => "19",
          "NAGANO"    => "20",
          "GIFU"      => "21",
          "SHIZUOKA"  => "22",
          "AICHI"     => "23",
          "MIE"       => "24",
          "SHIGA"     => "25",
          "KYOTO"     => "26",
          "OSAKA"     => "27",
          "HYOGO"     => "28",
          "NARA"      => "29",
          "WAKAYAMA"  => "30",
          "TOTTORI"   => "31",
          "SHIMANE"   => "32",
          "OKAYAMA"   => "33",
          "HIROSHIMA" => "34",
          "YAMAGUCHI" => "35",
          "TOKUSHIMA" => "36",
          "KAGAWA"    => "37",
          "EHIME"     => "38",
          "KOCHI"     => "39",
          "FUKUOKA"   => "40",
          "SAGA"      => "41",
          "NAGASAKI"  => "42",
          "KUMAMOTO"  => "43",
          "OITA"      => "44",
          "MIYAZAKI"  => "45",
          "KAGOSHIMA" => "46",
          "OKINAWA"   => "47" }

  ROSAI_KATAKANA="　" +
                 "ー" +
                 "アイウエオカガキギクグ" +
                 "ケゲコゴサザシジスズセゼソゾタダ" +
                 "チヂツヅテデトドナニヌネノハバ" +
                 "パヒビピフブプヘベペホボポマミ" +
                 "ムメモヤユヨラリルレロワ" +
                 "ヲンヴ"

  FORMSBT={"2" => [NYUIN ,TANKI],
           "3" => [GAIRAI,TANKI],
           "4" => [NYUIN ,CHOKI],
           "5" => [GAIRAI,CHOKI]}

  RECEKA={"01" => "内科",
          "02" => "精神科",
          "03" => "神経科",
          "04" => "神経内科",
          "05" => "呼吸器科",
          "06" => "消化器科",
          "07" => "胃腸科",
          "08" => "循環器科",
          "09" => "小児科",
          "10" => "外科",
          "11" => "整形外科",
          "12" => "形成外科",
          "13" => "美容外科",
          "14" => "脳神経外科",
          "15" => "呼吸器外科",
          "16" => "心臓血管外科",
          "17" => "小児外科",
          "18" => "皮膚泌尿器科",
          "19" => "皮膚科",
          "20" => "泌尿器科",
          "21" => "性病科",
          "22" => "こう門科",
          "23" => "産婦人科",
          "24" => "産科",
          "25" => "婦人科",
          "26" => "眼科",
          "27" => "耳鼻いんこう科",
          "28" => "気管食道科",
          "30" => "放射線科",
          "31" => "麻酔科",
          "33" => "心療内科",
          "34" => "アレルギー科",
          "35" => "リウマチ科",
          "36" => "リハビリテーション科",
          "37" => "病理診断科",
          "38" => "臨床検査科",
          "39" => "救急科" }
end
