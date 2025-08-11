import type { CalendarDate, CalendarEvent, WeekDay, CalendarHour } from './types'

// 获取月份的第一天是星期几 (0=周日, 1=周一, ...)
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

// 检查是否是同一天
export function isSameDay(date1: Date, date2: Date): boolean {
    return date1.getDate() === date2.getDate() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getFullYear() === date2.getFullYear()
}

// 格式化日期为 YYYY-MM-DD
export function formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    return `${year}-${month}-${day}`
}

// 解析日期字符串
export function parseDate(dateString: string): Date {
    return new Date(dateString)
}

// 获取月视图的日期数组（包含上月和下月的日期）
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
            isPrevMonth: true,
            isNextMonth: false,
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
            isPrevMonth: false,
            isNextMonth: false,
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
            isPrevMonth: false,
            isNextMonth: true,
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
        const hours = generateHoursForDay(currentDate, dayEvents)
        
        weekDays.push({
            date: currentDate,
            day: currentDate.getDate(),
            isToday: isToday(currentDate),
            isCurrentMonth: currentDate.getMonth() === date.getMonth(),
            isPrevMonth: currentDate.getMonth() < date.getMonth(),
            isNextMonth: currentDate.getMonth() > date.getMonth(),
            events: dayEvents,
            hours
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

// 为某一天生成小时块
export function generateHoursForDay(date: Date, events: CalendarEvent[]): CalendarHour[] {
    const hours: CalendarHour[] = []
    
    for (let hour = 0; hour < 24; hour++) {
        const hourEvents = events.filter(event => {
            if (!event.startTime) return hour === 0 && event.allDay // 全天事件放在第0小时
            const startHour = parseInt(event.startTime.split(':')[0])
            const endHour = event.endTime ? parseInt(event.endTime.split(':')[0]) : startHour + 1
            return hour >= startHour && hour < endHour
        })
        
        hours.push({
            hour,
            events: hourEvents
        })
    }
    
    return hours
}

// 获取星期名称
export function getWeekdayName(dayIndex: number, short = false): string {
    const weekdays = short 
        ? ['日', '一', '二', '三', '四', '五', '六']
        : ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
    return weekdays[dayIndex]
}

// 获取月份名称
export function getMonthName(monthIndex: number): string {
    const months = [
        '一月', '二月', '三月', '四月', '五月', '六月',
        '七月', '八月', '九月', '十月', '十一月', '十二月'
    ]
    return months[monthIndex]
}

// 生成日历标题
export function getCalendarTitle(date: Date, viewType: 'day' | 'week' | 'month'): string {
    const year = date.getFullYear()
    const month = date.getMonth() + 1
    const day = date.getDate()
    
    switch (viewType) {
        case 'day':
            return `${year}年${month}月${day}日`
        case 'week':
            const weekStart = new Date(date)
            weekStart.setDate(date.getDate() - date.getDay())
            const weekEnd = new Date(weekStart)
            weekEnd.setDate(weekStart.getDate() + 6)
            
            if (weekStart.getMonth() === weekEnd.getMonth()) {
                return `${year}年${weekStart.getMonth() + 1}月${weekStart.getDate()}日-${weekEnd.getDate()}日`
            } else {
                return `${year}年${weekStart.getMonth() + 1}月${weekStart.getDate()}日-${weekEnd.getMonth() + 1}月${weekEnd.getDate()}日`
            }
        case 'month':
            return `${year}年${month}月`
        default:
            return `${year}年${month}月`
    }
}

// 获取事件的优先级颜色
export function getPriorityColor(priority?: string): string {
    switch (priority) {
        case 'urgent':
            return '#ef4444' // 红色
        case 'high':
            return '#f97316' // 橙色
        case 'medium':
            return '#eab308' // 黄色
        case 'low':
            return '#22c55e' // 绿色
        default:
            return '#6b7280' // 灰色
    }
}

// 获取状态颜色
export function getStateColor(state?: string): string {
    switch (state) {
        case 'todo':
            return '#6b7280' // 灰色
        case 'in-progress':
            return '#3b82f6' // 蓝色
        case 'done':
            return '#22c55e' // 绿色
        default:
            return '#6b7280' // 灰色
    }
}