USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Item', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Item
    (
        item_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Item PRIMARY KEY,

        team_id INT NOT NULL,

        item_code NVARCHAR(50) NOT NULL,

        item_name NVARCHAR(200) NOT NULL,

        item_category NVARCHAR(50) NOT NULL,

        item_subcategory NVARCHAR(100) NULL,

        related_world_setting_id INT NULL,

        owner_character_id INT NULL,

        owner_npc_id INT NULL,

        current_location_setting_id INT NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Item_source_type
            DEFAULT N'transcript_extracted',

        source_reference NVARCHAR(200) NULL,

        introduced_session_no INT NULL,

        introduced_scene_no INT NULL,

        introduced_turn_no INT NULL,

        item_description_raw NVARCHAR(MAX) NULL,

        item_description_clean NVARCHAR(MAX) NULL,

        item_description_verified NVARCHAR(MAX) NULL,

        item_summary NVARCHAR(MAX) NULL,

        narrative_function NVARCHAR(200) NULL,

        mechanical_effect NVARCHAR(MAX) NULL,

        related_rule_code NVARCHAR(50) NULL,

        is_clue BIT NOT NULL
            CONSTRAINT DF_Item_is_clue
            DEFAULT 0,

        is_consumable BIT NOT NULL
            CONSTRAINT DF_Item_is_consumable
            DEFAULT 0,

        is_unique BIT NOT NULL
            CONSTRAINT DF_Item_is_unique
            DEFAULT 0,

        quantity INT NULL,

        item_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Item_item_status
            DEFAULT N'draft',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Item_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Item_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Item_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_Item_Related_World_Setting
            FOREIGN KEY (related_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT FK_Item_Owner_Player_Character
            FOREIGN KEY (owner_character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT FK_Item_Owner_NPC
            FOREIGN KEY (owner_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT FK_Item_Current_Location_World_Setting
            FOREIGN KEY (current_location_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT UQ_Item_Team_ItemCode
            UNIQUE (team_id, item_code),

        CONSTRAINT CK_Item_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(item_code))) > 0),

        CONSTRAINT CK_Item_Name_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(item_name))) > 0),

        CONSTRAINT CK_Item_Category
            CHECK (item_category IN (
                N'equipment',
                N'weapon',
                N'armor',
                N'consumable',
                N'clue',
                N'document',
                N'artifact',
                N'magic_item',
                N'technology',
                N'currency',
                N'resource',
                N'quest_item',
                N'symbolic_object',
                N'environment_object',
                N'other'
            )),

        CONSTRAINT CK_Item_Source_Type
            CHECK (source_type IN (
                N'gm_prepared',
                N'player_created',
                N'human_created',
                N'ai_generated',
                N'ai_summarized',
                N'human_modified',
                N'transcript_extracted',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_Item_Introduced_Session_No
            CHECK (
                introduced_session_no IS NULL
                OR introduced_session_no >= 1
            ),

        CONSTRAINT CK_Item_Introduced_Scene_No
            CHECK (
                introduced_scene_no IS NULL
                OR introduced_scene_no >= 1
            ),

        CONSTRAINT CK_Item_Introduced_Turn_No
            CHECK (
                introduced_turn_no IS NULL
                OR introduced_turn_no >= 1
            ),

        CONSTRAINT CK_Item_Quantity
            CHECK (
                quantity IS NULL
                OR quantity >= 0
            ),

        CONSTRAINT CK_Item_Owner_Only_One
            CHECK (
                owner_character_id IS NULL
                OR owner_npc_id IS NULL
            ),

        CONSTRAINT CK_Item_Status
            CHECK (item_status IN (
                N'draft',
                N'cleaned',
                N'verified',
                N'in_play',
                N'used',
                N'consumed',
                N'lost',
                N'transferred',
                N'destroyed',
                N'inactive',
                N'excluded'
            ))
    );
END;
GO