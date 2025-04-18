## PRD: 排班助手 - 模块: 统计分析 (Statistics) 功能拓展

**文档目的**: 本文档定义统计分析模块的下一阶段功能拓展。

---

### 功能拓展 3.1: 交互式图表 (Interactive Charts)

*   **目标**: 增强统计图表的可交互性，允许用户通过点击图表元素深入探索数据细节。
*   **用户故事**:
    *   作为一名用户，在查看月度班次类型分布饼图时，我希望能点击代表“夜班”的部分，直接查看这个月所有夜班的具体日期列表。
    *   作为一名用户，在查看月度工时统计柱状图时，我希望能点击某一天的柱子，快速跳转到日历上那一天查看详情。
*   **功能需求 (FR)**:
    *   FR3.1.1: **图表点击支持**: 更新现有图表库 (`fl_chart`) 或配置，使其支持点击事件。
    *   FR3.1.2: **饼图交互**: 点击饼图的某个扇区（代表某个班次类型）后，应能触发动作，如：
        *   在图表下方或新页面展示该月属于该班次类型的所有日期列表。
        *   高亮显示该扇区。
    *   FR3.1.3: **柱状图/折线图交互**: 点击图表上的某个数据点（代表某一天或某一统计值）后，应能触发动作，如：
        *   显示该数据点的具体数值 tooltip。
        *   （若适用）跳转到日历视图并定位到对应日期。
    *   FR3.1.4: **交互反馈**: 提供清晰的视觉反馈（如高亮、动画）表明用户点击了图表的哪个部分。
*   **非功能需求 (NFR)**:
    *   NFR3.1.1: **响应性**: 点击图表后的交互响应应及时。
*   **UI/UX**:
    *   交互方式应符合用户预期（单击或长按）。
    *   钻取（Drill-down）后的数据展示要清晰。
*   **依赖**: 无新增强依赖。

---

### 功能拓展 3.2: 统计维度扩展 (Expanded Statistics Dimensions)

*   **目标**: 提供更多维度和时间跨度的统计分析，帮助用户更全面地了解工作模式和趋势。
*   **用户故事**:
    *   作为一名用户，我希望能查看年度统计报告，了解全年的总工时、各类班次天数以及月度工时变化趋势。
    *   作为一名用户，我希望能看到一个年度日历热力图，直观地看出哪些月份或日期工作比较集中或休息较多。
    *   作为一名用户，我希望能比较任意两个月份或年份的工时、班次类型分布等数据，分析变化情况。
*   **功能需求 (FR)**:
    *   FR3.2.1: **时间范围选择**: 在统计页面增加时间范围选择器，支持按月、按年、或自定义时间范围查看统计。
    *   FR3.2.2: **年度统计报告**:
        *   提供年度视图，汇总全年的总工时、平均月/周工时、各类班次总天数。
        *   展示月度工时变化的折线图或柱状图。
    *   FR3.2.3: **年度日历热力图**:
        *   实现类似GitHub贡献图的日历热力图。
        *   颜色深浅代表每日工作时长或是否为工作日。
        *   支持点击热力图上的某一天跳转到日历。
    *   FR3.2.4: **对比分析**:
        *   允许用户选择两个不同的时间段（如“本月”与“上月”，“今年”与“去年”）。
        *   并排展示两个时间段的关键统计数据（工时、班次天数等）及差异百分比。
        *   提供对比图表（如双柱状图）。
    *   FR3.2.5: **数据聚合逻辑**: 实现按年、按月、按周聚合班次数据的后端逻辑。
*   **非功能需求 (NFR)**:
    *   NFR3.2.1: **性能**: 年度数据聚合和图表渲染不应过慢。
    *   NFR3.2.2: **准确性**: 统计数据计算必须准确。
*   **UI/UX**:
    *   统计页面需要重新组织以容纳更多图表和时间选择。
    *   热力图和对比分析的展示需要直观易懂。
*   **依赖**: 需要高效的数据库查询和数据聚合能力。

---
