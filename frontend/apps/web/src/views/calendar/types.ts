// 日历视图类型定义
export type CalendarViewType = 'day' | 'week' | 'month'

// 日历事件/待办任务接口
export interface CalendarEvent {
    id: string | number
    title: string
    startDate: string  // YYYY-MM-DD格式
    endDate?: string   // 可选的结束日期
    startTime?: string // HH:mm格式，可选时间
    endTime?: string   // HH:mm格式，可选结束时间
    allDay?: boolean   // 是否全天事件
    color?: string     // 事件颜色
    description?: string
    priority?: 'low' | 'medium' | 'high' | 'urgent'
    state?: 'todo' | 'in-progress' | 'done'
}

// 日历日期接口
export interface CalendarDate {
    date: Date
    day: number
    isToday: boolean
    isCurrentMonth: boolean
    isPrevMonth: boolean
    isNextMonth: boolean
    events: CalendarEvent[]
}

// 周视图的一天数据
export interface WeekDay extends CalendarDate {
    hours: CalendarHour[]
}

// 小时块数据
export interface CalendarHour {
    hour: number
    events: CalendarEvent[]
}

// 日历导航数据
export interface CalendarNavigation {
    currentDate: Date
    viewType: CalendarViewType
    title: string
}