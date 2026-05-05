# TRPG 共創語料資料庫：正式表關聯圖

本文件整理 `TRPG_Corpus_DB` 中二十個 `dbo` 正式表之間的主要關聯。格式採用：

```text
父表
    1 ──── N 子表
        關聯說明
```

---

## 1. Research_Project

```text
dbo.Research_Project
    1 ──── N dbo.Team
    1 ──── N dbo.Player
    1 ──── N dbo.Game_Rule
    1 ──── N dbo.World_Setting
    1 ──── N dbo.Expert_Rating
```

---

## 2. Team

```text
dbo.Team
    1 ──── N dbo.Team_Member
    1 ──── N dbo.NPC
    1 ──── N dbo.World_Setting
    1 ──── N dbo.Item
    1 ──── N dbo.TRPG_Session
    1 ──── N dbo.Team_Play_History
    1 ──── N dbo.Extended_Creation_Text
    1 ──── N dbo.Expert_Rating
```

---

## 3. Player

```text
dbo.Player
    1 ──── N dbo.Team_Member
    1 ──── N dbo.Expert_Rating
        當 Player.participant_role = N'expert' 時，作為匿名專家評分者
```

---

## 4. Team_Member

```text
dbo.Team_Member
    1 ──── N dbo.Player_Character
    1 ──── N dbo.NPC
        當 controller_member_id 記錄 NPC 控制者時
    1 ──── N dbo.TRPG_Session
        當成員是 gm_member_id、recorder_member_id、observer_member_id 時
    1 ──── N dbo.Utterance
        當 speaker_type = GM、PL、Observer、Researcher 時
    1 ──── N dbo.Plot_Event
        當 actor_type = team_member 或 gm 時
    1 ──── N dbo.Decision_Log
        當 proposer_member_id 或 final_actor_member_id 有值時
    1 ──── N dbo.Knowledge_Retrieval_Log
        當 query_initiator_member_id 有值時
    1 ──── N dbo.Extended_Creation_Text
        當 author_member_id 有值時
```

---

## 5. Player_Character

```text
dbo.Player_Character
    1 ──── N dbo.Item
        當玩家角色持有物件時
    1 ──── N dbo.Utterance
        當 speaker_type = PC 時
    1 ──── N dbo.Plot_Event
        當 actor_character_id 或 target_character_id 有值時
    1 ──── N dbo.Decision_Log
        當 proposer_character_id 或 final_actor_character_id 有值時
    1 ──── N dbo.Knowledge_Retrieval_Log
        當 query_initiator_character_id 有值時
```

---

## 6. NPC

```text
dbo.NPC
    1 ──── N dbo.Item
        當 NPC 持有物件時
    1 ──── N dbo.Utterance
        當 speaker_type = NPC 時
    1 ──── N dbo.GM_Narration
        當 GM 旁白涉及 NPC 時
    1 ──── N dbo.Plot_Event
        當 actor_npc_id 或 target_npc_id 有值時
    1 ──── N dbo.Decision_Log
        當 proposer_npc_id 有值時
    1 ──── N dbo.Team_Play_History
        當團隊歷程涉及主要 NPC 時
    1 ──── N dbo.Extended_Creation_Text
        當延伸創作引用 NPC 時
```

---

## 7. Game_Rule

```text
dbo.Game_Rule
    1 ──── N dbo.Utterance
        當發言涉及規則、檢定、房規時
    1 ──── N dbo.GM_Narration
        當 GM 旁白提示規則或檢定時
    1 ──── N dbo.Plot_Event
        當事件由規則結算產生時
    1 ──── N dbo.Decision_Log
        當決策依據規則或規則解釋時
    1 ──── N dbo.Knowledge_Retrieval_Log
        當查詢命中規則資料時
```

---

## 8. World_Setting

```text
dbo.World_Setting
    1 ──── N dbo.World_Setting
        透過 parent_world_setting_id 建立世界觀階層
    1 ──── N dbo.Item
        當物件連到地點、陣營、歷史或世界觀條目時
    1 ──── N dbo.Scene
        當場景連到特定地點或世界觀條目時
    1 ──── N dbo.Utterance
        當發言涉及世界觀、地點、陣營或背景時
    1 ──── N dbo.GM_Narration
        當 GM 旁白揭露世界觀時
    1 ──── N dbo.Plot_Event
        當事件涉及世界觀狀態改變或設定揭露時
    1 ──── N dbo.Decision_Log
        當決策涉及地點、陣營、世界觀或背景時
    1 ──── N dbo.Knowledge_Retrieval_Log
        當查詢命中世界觀資料時
    1 ──── N dbo.Team_Play_History
        當團隊歷程以某世界觀條目為主要對象時
    1 ──── N dbo.Extended_Creation_Text
        當延伸創作引用世界觀條目時
```

---

## 9. Item

```text
dbo.Item
    1 ──── N dbo.Utterance
        當發言涉及道具、線索、文件或資源時
    1 ──── N dbo.GM_Narration
        當 GM 旁白描述物件或線索時
    1 ──── N dbo.Plot_Event
        當事件涉及取得、使用、失去或破壞物件時
    1 ──── N dbo.Decision_Log
        當決策涉及物件、線索或資源時
    1 ──── N dbo.Knowledge_Retrieval_Log
        當查詢命中物件資料時
    1 ──── N dbo.Team_Play_History
        當團隊歷程以某物件為主要對象時
    1 ──── N dbo.Extended_Creation_Text
        當延伸創作引用物件或線索時
```

---

## 10. TRPG_Session

```text
dbo.TRPG_Session
    1 ──── N dbo.Scene
    1 ──── N dbo.Utterance
    1 ──── N dbo.GM_Narration
    1 ──── N dbo.Plot_Event
    1 ──── N dbo.Event_Causal_Link
    1 ──── N dbo.Decision_Log
    1 ──── N dbo.Knowledge_Retrieval_Log
    1 ──── N dbo.Team_Play_History
    1 ──── N dbo.Extended_Creation_Text
```

---

## 11. Scene

```text
dbo.Scene
    1 ──── N dbo.Scene
        透過 parent_scene_id 建立子場景或拆分場景
    1 ──── N dbo.Utterance
    1 ──── N dbo.GM_Narration
    1 ──── N dbo.Plot_Event
    1 ──── N dbo.Event_Causal_Link
    1 ──── N dbo.Decision_Log
    1 ──── N dbo.Knowledge_Retrieval_Log
    1 ──── N dbo.Team_Play_History
    1 ──── N dbo.Extended_Creation_Text
    1 ──── N dbo.Expert_Rating
        當評分對象為場景時
```

---

## 12. Utterance

```text
dbo.Utterance
    1 ──── 0..1 dbo.GM_Narration
        一筆 GM 旁白發言最多對應一筆 GM_Narration
    1 ──── N dbo.Plot_Event
        透過 start_utterance_id、end_utterance_id、source_utterance_id 追溯事件來源
    1 ──── N dbo.Event_Causal_Link
        透過 evidence_utterance_id 作為因果證據
    1 ──── N dbo.Decision_Log
        透過 start_utterance_id、end_utterance_id、source_utterance_id、final_decision_utterance_id 追溯決策
    1 ──── N dbo.Knowledge_Retrieval_Log
        透過 source_utterance_id、query_start_utterance_id、query_end_utterance_id 追溯查詢
    1 ──── N dbo.Team_Play_History
        透過 start_utterance_id、end_utterance_id 追溯歷程範圍
    1 ──── N dbo.Extended_Creation_Text
        透過 source_start_utterance_id、source_end_utterance_id 追溯創作素材來源
```

---

## 13. GM_Narration

```text
dbo.GM_Narration
    1 ──── N dbo.Plot_Event
        當事件由 GM 旁白抽取時
    1 ──── N dbo.Event_Causal_Link
        當 GM 旁白作為因果證據時
```

---

## 14. Plot_Event

```text
dbo.Plot_Event
    1 ──── N dbo.Event_Causal_Link
        透過 cause_event_id 作為原因事件
    1 ──── N dbo.Event_Causal_Link
        透過 effect_event_id 作為結果事件
    1 ──── N dbo.Decision_Log
        當決策依據事件或造成事件時
    1 ──── N dbo.Knowledge_Retrieval_Log
        當查詢與事件有關時
    1 ──── N dbo.Team_Play_History
        當團隊歷程引用事件時
    1 ──── N dbo.Extended_Creation_Text
        當延伸創作引用事件時
    1 ──── N dbo.Expert_Rating
        當評分對象為劇情事件時
```

---

## 15. Event_Causal_Link

```text
dbo.Event_Causal_Link
    1 ──── N dbo.Decision_Log
        當決策連到既有事件因果時
    1 ──── N dbo.Knowledge_Retrieval_Log
        當查詢與因果判斷有關時
    1 ──── N dbo.Team_Play_History
        當團隊歷程引用因果鏈時
```

---

## 16. Decision_Log

```text
dbo.Decision_Log
    1 ──── N dbo.Event_Causal_Link
        當決策作為因果證據時，透過 evidence_decision_id
    1 ──── N dbo.Knowledge_Retrieval_Log
        當查詢支援某項決策時
    1 ──── N dbo.Team_Play_History
        當團隊歷程引用決策時
    1 ──── N dbo.Extended_Creation_Text
        當延伸創作引用決策時
    1 ──── N dbo.Expert_Rating
        當評分對象為決策時
```

---

## 17. Knowledge_Retrieval_Log

```text
dbo.Knowledge_Retrieval_Log
    1 ──── N dbo.Team_Play_History
        當團隊歷程引用資料庫查詢或知識檢索時
    1 ──── N dbo.Extended_Creation_Text
        當延伸創作引用查詢結果或知識素材時
```

---

## 18. Team_Play_History

```text
dbo.Team_Play_History
    1 ──── N dbo.Extended_Creation_Text
        當延伸創作取材自團隊遊玩歷程時
    1 ──── N dbo.Expert_Rating
        當評分對象為團隊遊玩歷程時
```

---

## 19. Extended_Creation_Text

```text
dbo.Extended_Creation_Text
    1 ──── N dbo.Expert_Rating
        當專家評分對象為延伸創作文本時
```

---

## 整體主鏈

```text
dbo.Research_Project
    1 ──── N dbo.Team
        1 ──── N dbo.Team_Member
            1 ──── N dbo.Player_Character

        1 ──── N dbo.NPC
        1 ──── N dbo.World_Setting
        1 ──── N dbo.Item
        1 ──── N dbo.TRPG_Session
            1 ──── N dbo.Scene
                1 ──── N dbo.Utterance
                    1 ──── 0..1 dbo.GM_Narration

            1 ──── N dbo.Plot_Event
                1 ──── N dbo.Event_Causal_Link

            1 ──── N dbo.Decision_Log
            1 ──── N dbo.Knowledge_Retrieval_Log
            1 ──── N dbo.Team_Play_History
                1 ──── N dbo.Extended_Creation_Text
                    1 ──── N dbo.Expert_Rating
```

---

## 橫向參照表

`dbo.Game_Rule`、`dbo.World_Setting`、`dbo.Item` 是橫向參照表，會被逐字稿、旁白、事件、決策、查詢、歷程與創作成果引用。

```text
dbo.Game_Rule
    1 ──── N dbo.Utterance
    1 ──── N dbo.GM_Narration
    1 ──── N dbo.Plot_Event
    1 ──── N dbo.Decision_Log
    1 ──── N dbo.Knowledge_Retrieval_Log

dbo.World_Setting
    1 ──── N dbo.Scene
    1 ──── N dbo.Item
    1 ──── N dbo.Utterance
    1 ──── N dbo.GM_Narration
    1 ──── N dbo.Plot_Event
    1 ──── N dbo.Decision_Log
    1 ──── N dbo.Knowledge_Retrieval_Log
    1 ──── N dbo.Team_Play_History
    1 ──── N dbo.Extended_Creation_Text

dbo.Item
    1 ──── N dbo.Utterance
    1 ──── N dbo.GM_Narration
    1 ──── N dbo.Plot_Event
    1 ──── N dbo.Decision_Log
    1 ──── N dbo.Knowledge_Retrieval_Log
    1 ──── N dbo.Team_Play_History
    1 ──── N dbo.Extended_Creation_Text
```
