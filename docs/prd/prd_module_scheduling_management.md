## PRD: 排班助手 - 模块: 排班管理 (核心调度与日历视图) 功能拓展

**文档目的**: 本文档定义排班管理模块的下一阶段功能拓展。

---

### 功能拓展 1.1: 班次模板 (Shift Templates)

*   **目标**: 允许用户创建、保存和快速应用常用的排班模式，提高排班效率，减少重复操作。
*   **用户故事**:
    *   作为一名需要按周或月重复固定排班模式的用户，我希望能将这个模式保存为模板，以便下次能一键应用到指定日期范围，节省排班时间。
    *   作为一名新用户或需要安排常见班次（如周一至周五 9-5）的用户，我希望能直接选用预设的常见模板，快速开始排班。
    *   作为一名管理员，我希望能管理（创建、编辑、删除）我的班次模板。
*   **功能需求 (FR)**:
    *   FR1.1.1: **模板创建**:
        *   入口: 在排班管理界面或设置界面提供"班次模板管理"入口。
        *   操作: 用户可以新建模板，定义模板名称（必填，唯一性检查）。
        *   内容: 模板包含一个时间周期（如7天、14天、一个月）内每一天的班次安排。用户可以为周期内的每一天选择已定义的“班次类型”（关联模块二）或选择“休息”。
        *   保存: 验证通过后保存模板。
    *   FR1.1.2: **模板管理**:
        *   列表: 在"班次模板管理"界面，以列表形式展示用户创建的所有模板。
        *   操作: 支持查看模板详情、编辑模板内容、删除模板（需二次确认）。
    *   FR1.1.3: **预设模板**:
        *   提供若干常见的预设模板（如“标准工作周”、“做一休一”等），用户不可编辑或删除预设模板，但可以复制预设模板来创建自己的模板。
    *   FR1.1.4: **模板应用**:
        *   入口: 在日历视图的长按菜单、批量排班功能中增加"应用模板"选项。
        *   流程:
            1.  用户选择一个"起始日期"。
            2.  用户选择一个要应用的"班次模板"（包含预设和自定义模板）。
            3.  用户选择应用的"重复次数"或"结束日期"。
            4.  系统**预览**将要生成的排班（在日历上高亮显示或列表展示），明确显示哪些日期的现有班次将被覆盖。
            5.  用户确认应用。
        *   冲突处理: 应用模板时，明确告知用户所选日期范围内已存在的班次将被模板内容**覆盖**。提供覆盖前确认。
        *   数据写入: 确认后，根据模板和日期范围，批量生成或更新 `Shift` 数据。
    *   FR1.1.5: **模板数据存储**: 模板数据需要持久化存储在本地数据库。
*   **非功能需求 (NFR)**:
    *   NFR1.1.1: **易用性**: 模板创建和应用流程应直观易懂。
    *   NFR1.1.2: **性能**: 应用模板（特别是跨度较长时）不应导致界面卡顿。
*   **UI/UX**:
    *   需要设计"班次模板管理"界面。
    *   模板应用流程中，预览步骤至关重要。
    *   在日历视图中，可以考虑用不同视觉样式标记由模板应用的班次。
*   **依赖**: 依赖 "班次类型" 模块提供可选的班次。

---

### 功能拓展 1.2: 智能排班辅助 (Smart Scheduling Assistant)

*   **目标**: 基于用户设定的规则和偏好，在排班时提供警告和建议，帮助用户创建更合规、更人性化的班次安排。
*   **用户故事**:
    *   作为一名需要遵守工时规定的用户，我希望在安排班次时，如果违反了“连续工作不得超过X天”或“每日工时不得超过Y小时”的规则，App能给我警告提示，避免违规。
    *   作为一名有特定工作偏好的用户（如“尽量避免连续上夜班”），我希望能设置这些偏好，App在排班时能基于偏好给出建议或警告。
*   **功能需求 (FR)**:
    *   FR1.2.1: **规则配置**:
        *   入口: 在设置界面增加"排班规则"配置项。
        *   可配置规则（示例）:
            *   最大连续工作天数 (默认关闭, 可设置 1-14 天)。
            *   两次排班之间最小休息时间 (默认关闭, 可设置 1-24 小时)。
            *   每周最大工作时长 (默认关闭, 可设置 1-168 小时)。
            *   单日最大工作时长 (默认关闭, 可设置 1-24 小时)。
        *   数据存储: 规则配置需持久化。
    *   FR1.2.2: **规则校验与警告**:
        *   触发时机: 在用户**添加**或**编辑**单个班次、**应用班次模板**或**批量排班**后。
        *   校验逻辑: 系统根据用户配置的规则，检查新生成的排班是否触发规则限制。检查范围应包括受影响日期及其前后关联日期。
        *   警告方式:
            *   在日历视图上，对违反规则的日期或班次进行**视觉标记**（如红色边框、警告图标）。
            *   在保存操作时，如果触发规则，弹窗提示用户具体违反了哪条规则，用户可选择“强制保存”或“取消”。
    *   FR1.2.3: **排班偏好设置 (可选/高级功能)**:
        *   入口: "排班规则"配置项内。
        *   可配置偏好（示例）:
            *   倾向的班次类型（如“优先安排白班”）。
            *   避免的排班模式（如“避免连续夜班”）。
    *   FR1.2.4: **基于偏好的建议 (可选/高级功能)**:
        *   触发时机: 用户在空白日期上尝试排班时。
        *   建议逻辑: 根据用户偏好和已有排班，推荐1-2个合适的班次类型。
        *   呈现方式: 在班次选择对话框中，优先显示推荐的班次类型。
*   **非功能需求 (NFR)**:
    *   NFR1.2.1: **性能**: 规则校验不应显著增加排班操作的响应时间。
    *   NFR1.2.2: **可配置性**: 用户应能方便地启用/禁用及调整规则。
*   **UI/UX**:
    *   规则配置界面需要清晰易懂。
    *   日历上的视觉警告标记需要明确且不过于干扰。
    *   警告弹窗信息需准确说明违反的规则。
*   **依赖**: 规则校验需读取历史班次数据。

---

### 功能拓展 1.3: 高级搜索 (Advanced Search)

*   **目标**: 提供更强大的班次搜索能力，方便用户快速查找特定条件的排班记录。
*   **用户故事**:
    *   作为一名用户，我希望能按日期范围（如“上个月”）和班次类型（如“夜班”）搜索我的排班记录，以便回顾或统计。
    *   作为一名用户，我希望能根据班次备注中的关键词（如“会议”、“培训”）搜索相关的排班，快速定位特定事件。
*   **功能需求 (FR)**:
    *   FR1.3.1: **搜索入口**: 在主界面（如AppBar）或统计/我的页面增加搜索入口图标。
    *   FR1.3.2: **搜索条件**:
        *   日期范围: 支持选择预设范围（本周、本月、上月、今年）或自定义起止日期。
        *   班次类型: 支持多选已定义的班次类型进行筛选。
        *   备注关键词: 支持输入文本进行备注内容的模糊匹配搜索。
        *   组合搜索: 支持以上条件的组合搜索。
    *   FR1.3.3: **搜索执行**: 点击搜索按钮后，根据选定条件查询本地数据库。
    *   FR1.3.4: **搜索结果展示**:
        *   以列表形式展示符合条件的班次记录。
        *   每条记录显示日期、班次类型、起止时间（若有）、备注（高亮关键词）。
        *   结果列表支持按日期排序（升序/降序）。
        *   点击单条结果，可以跳转到日历视图并定位到该日期。
    *   FR1.3.5: **无结果提示**: 如果没有找到符合条件的班次，显示清晰的提示信息。
*   **非功能需求 (NFR)**:
    *   NFR1.3.1: **性能**: 搜索响应时间应在可接受范围内（< 2秒）。对于大量数据，考虑优化查询或分页加载。
*   **UI/UX**:
    *   需要设计搜索条件选择界面和搜索结果展示界面。
    *   搜索条件的组合方式需要清晰。
    *   结果列表信息应简洁明了。
*   **依赖**: 依赖班次数据和班次类型数据。

---
