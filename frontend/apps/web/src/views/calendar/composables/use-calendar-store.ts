import { ref, computed, watch } from 'vue'
import { defineStore } from 'pinia'
import { useTodoStore } from '../../../stores/use-todo-store'
import type { CalendarViewType, CalendarEvent, CalendarNavigation } from '../types'
import { getCalendarTitle } from '../utils'
import { useMoment } from '@nao-todo/utils'

export const useCalendarStore = defineStore('calendar', () => {
    // ===== State =====
    const currentDate = ref(new Date())
    const viewType = ref<CalendarViewType>('month')
    const selectedDate = ref<Date | null>(null)
    const isLoading = ref(false)

    // ===== Getters =====
    const navigation = computed<CalendarNavigation>(() => ({
        currentDate: currentDate.value,
        viewType: viewType.value,
        title: getCalendarTitle(currentDate.value, viewType.value)
    }))

    // 获取日历事件（从todos转换而来）
    const events = computed<CalendarEvent[]>(() => {
        const todoStore = useTodoStore()
        return todoStore.todos.filter(todo => !todo.isDeleted && !todo.isArchived).map(todo => {
            // 从datetime字符串中提取时间部分
            let startTime: string | undefined = undefined
            let endTime: string | undefined = undefined
            
            if (todo.dueDate?.startAt) {
                // 直接使用原始时间，不进行时区转换
                const startMoment = useMoment(todo.dueDate.startAt)
                const timeStr = startMoment.format('HH:mm:ss')
                console.log('Start time analysis:', {
                    todoName: todo.name,
                    original: todo.dueDate.startAt,
                    directTime: startMoment.format('YYYY-MM-DD HH:mm:ss'),
                    timeStr: timeStr,
                    extractedTime: startMoment.format('HH:mm')
                })
                // 只要有设置开始时间，就提取时间（包括00:00）
                startTime = startMoment.format('HH:mm')
            }
            
            if (todo.dueDate?.endAt) {
                // 直接使用原始时间，不进行时区转换
                const endMoment = useMoment(todo.dueDate.endAt)
                const timeStr = endMoment.format('HH:mm:ss')
                console.log('End time analysis:', {
                    todoName: todo.name,
                    original: todo.dueDate.endAt,
                    directTime: endMoment.format('YYYY-MM-DD HH:mm:ss'),
                    timeStr: timeStr,
                    extractedTime: endMoment.format('HH:mm')
                })
                // 只要有设置结束时间，就提取时间（包括00:00）
                endTime = endMoment.format('HH:mm')
            }
            
            // 如果有具体的时间设置，则不是全天事件
            const hasSpecificTime = startTime || endTime || todo.dueDate?.startTime || todo.dueDate?.endTime
            // 如果有开始或结束时间，就不是全天事件
            const isAllDay = !hasSpecificTime
            
            // 如果没有设置任何日期，默认显示在今天
            let displayStartDate: string
            let displayEndDate: string | undefined
            
            if (todo.dueDate?.startAt || todo.dueDate?.endAt) {
                // 有设置日期的情况，直接使用原始日期不转换时区
                displayStartDate = todo.dueDate?.startAt ? useMoment(todo.dueDate.startAt).format('YYYY-MM-DD') : useMoment().format('YYYY-MM-DD')
                displayEndDate = todo.dueDate?.endAt ? useMoment(todo.dueDate.endAt).format('YYYY-MM-DD') : undefined
            } else {
                // 没有设置任何日期的情况，显示在今天
                displayStartDate = useMoment().format('YYYY-MM-DD')
                displayEndDate = undefined
            }
            
            const result = {
                id: todo.id,
                title: todo.name,
                startDate: displayStartDate,
                endDate: displayEndDate,
                startTime: startTime || todo.dueDate?.startTime || undefined,
                endTime: endTime || todo.dueDate?.endTime || undefined,
                allDay: isAllDay,
                priority: todo.priority,
                state: todo.state,
                description: todo.description || '',
                color: getPriorityColor(todo.priority),
                todo: todo // 保存原始todo对象供颜色增强使用
            }
            
            console.log('Calendar event created:', {
                todoName: todo.name,
                originalDueDate: todo.dueDate,
                resultEvent: result
            })
            
            return result
        })
    })

    const todayEvents = computed(() => {
        const today = useMoment().format('YYYY-MM-DD')
        return events.value.filter(event => {
            if (event.endDate) {
                return today >= event.startDate && today <= event.endDate
            }
            return event.startDate === today
        })
    })

    const selectedDateEvents = computed(() => {
        if (!selectedDate.value) return []
        const dateString = useMoment(selectedDate.value).format('YYYY-MM-DD')
        return events.value.filter(event => {
            if (event.endDate) {
                return dateString >= event.startDate && dateString <= event.endDate
            }
            return event.startDate === dateString
        })
    })

    // ===== Actions =====
    
    // 设置视图类型
    function setViewType(type: CalendarViewType) {
        viewType.value = type
    }

    // 设置当前日期
    function setCurrentDate(date: Date) {
        currentDate.value = new Date(date)
    }

    // 设置选中的日期
    function setSelectedDate(date: Date | null) {
        selectedDate.value = date ? new Date(date) : null
    }

    // 导航到今天
    function goToToday() {
        const today = new Date()
        setCurrentDate(today)
        setSelectedDate(today)
    }

    // 导航到上一个时间段
    function goToPrev() {
        const newDate = new Date(currentDate.value)
        
        switch (viewType.value) {
            case 'day':
                newDate.setDate(newDate.getDate() - 1)
                break
            case 'week':
                newDate.setDate(newDate.getDate() - 7)
                break
            case 'month':
                newDate.setMonth(newDate.getMonth() - 1)
                break
        }
        
        setCurrentDate(newDate)
    }

    // 导航到下一个时间段
    function goToNext() {
        const newDate = new Date(currentDate.value)
        
        switch (viewType.value) {
            case 'day':
                newDate.setDate(newDate.getDate() + 1)
                break
            case 'week':
                newDate.setDate(newDate.getDate() + 7)
                break
            case 'month':
                newDate.setMonth(newDate.getMonth() + 1)
                break
        }
        
        setCurrentDate(newDate)
    }

    // 加载日历数据
    async function loadCalendarData() {
        isLoading.value = true
        try {
            const todoStore = useTodoStore()
            
            // 设置获取选项以排除已删除和已归档的任务
            todoStore.updateGetOptions({
                isDeleted: false,
                isArchived: false,
                page: 1,
                limit: 200, // 日历视图需要更多数据
                sort: {
                    field: 'startAt',
                    order: 'asc'
                }
            })
            
            // 获取todos数据
            await todoStore.doGetTodos()
        } catch (error) {
            console.error('Failed to load calendar data:', error)
        } finally {
            isLoading.value = false
        }
    }

    // 刷新数据
    async function refresh() {
        await loadCalendarData()
    }

    // 获取优先级颜色的辅助函数
    function getPriorityColor(priority?: string): string {
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

    // 为重叠任务生成更好的颜色区分
    function getEnhancedColor(todo: any, columnIndex?: number): string {
        const baseColor = getPriorityColor(todo.priority)
        
        // 如果有列索引（重叠任务），提供颜色变化
        if (typeof columnIndex === 'number' && columnIndex > 0) {
            // 根据列索引调整颜色的色调和饱和度
            const colorVariations = [
                baseColor, // 原始颜色
                adjustColorBrightness(baseColor, -20), // 稍微暗一些
                adjustColorBrightness(baseColor, 20), // 稍微亮一些
                adjustColorHue(baseColor, 30), // 调整色调
                adjustColorHue(baseColor, -30), // 调整色调
            ]
            return colorVariations[columnIndex % colorVariations.length]
        }
        
        return baseColor
    }

    // 调整颜色亮度
    function adjustColorBrightness(hex: string, percent: number): string {
        const num = parseInt(hex.replace("#", ""), 16)
        const amt = Math.round(2.55 * percent)
        const R = (num >> 16) + amt
        const G = (num >> 8 & 0x00FF) + amt
        const B = (num & 0x0000FF) + amt
        return "#" + (0x1000000 + (R < 255 ? R < 1 ? 0 : R : 255) * 0x10000 +
            (G < 255 ? G < 1 ? 0 : G : 255) * 0x100 +
            (B < 255 ? B < 1 ? 0 : B : 255)).toString(16).slice(1)
    }

    // 调整颜色色调
    function adjustColorHue(hex: string, degree: number): string {
        const hsl = hexToHsl(hex)
        hsl.h = (hsl.h + degree) % 360
        if (hsl.h < 0) hsl.h += 360
        return hslToHex(hsl.h, hsl.s, hsl.l)
    }

    // 颜色格式转换辅助函数
    function hexToHsl(hex: string) {
        const r = parseInt(hex.slice(1, 3), 16) / 255
        const g = parseInt(hex.slice(3, 5), 16) / 255
        const b = parseInt(hex.slice(5, 7), 16) / 255

        const max = Math.max(r, g, b)
        const min = Math.min(r, g, b)
        let h = 0, s = 0, l = (max + min) / 2

        if (max === min) {
            h = s = 0
        } else {
            const d = max - min
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break
                case g: h = (b - r) / d + 2; break
                case b: h = (r - g) / d + 4; break
            }
            h /= 6
        }

        return { h: h * 360, s: s * 100, l: l * 100 }
    }

    function hslToHex(h: number, s: number, l: number): string {
        h /= 360
        s /= 100
        l /= 100

        const hue2rgb = (p: number, q: number, t: number) => {
            if (t < 0) t += 1
            if (t > 1) t -= 1
            if (t < 1/6) return p + (q - p) * 6 * t
            if (t < 1/2) return q
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6
            return p
        }

        const q = l < 0.5 ? l * (1 + s) : l + s - l * s
        const p = 2 * l - q
        const r = hue2rgb(p, q, h + 1/3)
        const g = hue2rgb(p, q, h)
        const b = hue2rgb(p, q, h - 1/3)

        const toHex = (c: number) => {
            const hex = Math.round(c * 255).toString(16)
            return hex.length === 1 ? '0' + hex : hex
        }

        return `#${toHex(r)}${toHex(g)}${toHex(b)}`
    }

    // 初始化数据
    function initialize() {
        goToToday()
        loadCalendarData()
    }

    // 监听视图类型变化，重新加载数据
    watch(viewType, () => {
        loadCalendarData()
    })

    return {
        // State
        currentDate,
        viewType,
        selectedDate,
        isLoading,
        
        // Getters
        navigation,
        events,
        todayEvents,
        selectedDateEvents,
        
        // Actions
        setViewType,
        setCurrentDate,
        setSelectedDate,
        goToToday,
        goToPrev,
        goToNext,
        loadCalendarData,
        refresh,
        initialize
    }
})