// 移动端日历工具函数

export interface CalendarEvent {
    id: string | number
    title: string
    startDate: string
    endDate?: string
    startTime?: string
    endTime?: string
    allDay?: boolean
    priority?: 'low' | 'medium' | 'high' | 'urgent'
    state?: 'todo' | 'in-progress' | 'done'
    description?: string
}

export interface CalendarDate {
    date: Date
    day: number
    isToday: boolean
    isCurrentMonth: boolean
    events: CalendarEvent[]
}

export interface WeekDay extends CalendarDate {
    // 周视图专用属性
}

// 获取月份的第一天是星期几
export function getFirstDayOfMonth(year: number, month: number): number {
    return new Date(year, month - 1, 1).getDay()
}

// 获取月份的天数
export function getDaysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate()
}

// 获取上个月的天数
export function getDaysInPrevMonth(year: number, month: number): number {
    return new Date(year, month - 1, 0).getDate()
}

// 检查是否是今天
export function isToday(date: Date): boolean {
    const today = new Date()
    return date.getDate() === today.getDate() &&
           date.getMonth() === today.getMonth() &&
           date.getFullYear() === today.getFullYear()
}

// 格式化日期为 YYYY-MM-DD
export function formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    return `${year}-${month}-${day}`
}

// 获取月视图的日期数组
export function getMonthViewDates(year: number, month: number, events: CalendarEvent[] = []): CalendarDate[] {
    const dates: CalendarDate[] = []
    const firstDay = getFirstDayOfMonth(year, month)
    const daysInMonth = getDaysInMonth(year, month)
    const daysInPrevMonth = getDaysInPrevMonth(year, month)
    
    // 添加上个月的日期
    for (let i = firstDay - 1; i >= 0; i--) {
        const day = daysInPrevMonth - i
        const date = new Date(year, month - 2, day)
        dates.push({
            date,
            day,
            isToday: isToday(date),
            isCurrentMonth: false,
            events: getEventsForDate(date, events)
        })
    }
    
    // 添加当月的日期
    for (let day = 1; day <= daysInMonth; day++) {
        const date = new Date(year, month - 1, day)
        dates.push({
            date,
            day,
            isToday: isToday(date),
            isCurrentMonth: true,
            events: getEventsForDate(date, events)
        })
    }
    
    // 补齐剩余位置（下个月的日期）
    const remainingDays = 42 - dates.length // 6行 * 7天
    for (let day = 1; day <= remainingDays; day++) {
        const date = new Date(year, month, day)
        dates.push({
            date,
            day,
            isToday: isToday(date),
            isCurrentMonth: false,
            events: getEventsForDate(date, events)
        })
    }
    
    return dates
}

// 获取周视图的日期数组
export function getWeekViewDates(date: Date, events: CalendarEvent[] = []): WeekDay[] {
    const startOfWeek = new Date(date)
    const day = startOfWeek.getDay()
    startOfWeek.setDate(startOfWeek.getDate() - day) // 调整到周日
    
    const weekDays: WeekDay[] = []
    
    for (let i = 0; i < 7; i++) {
        const currentDate = new Date(startOfWeek)
        currentDate.setDate(startOfWeek.getDate() + i)
        
        const dayEvents = getEventsForDate(currentDate, events)
        
        weekDays.push({
            date: currentDate,
            day: currentDate.getDate(),
            isToday: isToday(currentDate),
            isCurrentMonth: currentDate.getMonth() === date.getMonth(),
            events: dayEvents
        })
    }
    
    return weekDays
}

// 获取指定日期的事件
export function getEventsForDate(date: Date, events: CalendarEvent[]): CalendarEvent[] {
    const dateString = formatDate(date)
    return events.filter(event => {
        if (event.endDate) {
            // 多天事件
            return dateString >= event.startDate && dateString <= event.endDate
        } else {
            // 单天事件
            return event.startDate === dateString
        }
    })
}

// 获取星期名称
export function getWeekdayName(dayIndex: number, short = false): string {
    const weekdays = short 
        ? ['日', '一', '二', '三', '四', '五', '六']
        : ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
    return weekdays[dayIndex]
}