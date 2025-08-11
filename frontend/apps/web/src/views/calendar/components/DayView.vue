<template>
    <div class="day-view">
        <!-- 日期头部 -->
        <div class="day-header">
            <div class="date-info">
                <div class="weekday-name">{{ getWeekdayName(currentDate.getDay()) }}</div>
                <div :class="['date-number', { 'today': isToday }]">
                    {{ currentDate.getDate() }}
                </div>
                <div class="month-year">
                    {{ currentDate.getFullYear() }}年{{ currentDate.getMonth() + 1 }}月
                </div>
            </div>
            
        </div>

        <!-- 全天事件区域 -->
        <div class="all-day-section" v-if="allDayEvents.length > 0">
            <div class="section-header">
                <h3>全天事件</h3>
            </div>
            <div class="all-day-events">
                <div
                    v-for="event in allDayEvents"
                    :key="event.id"
                    :class="[
                        'all-day-event',
                        `event-${event.priority || 'default'}`,
                        { 'event-done': event.state === 'done' }
                    ]"
                    :style="{ backgroundColor: event.color }"
                    @click="handleEventClick(event)"
                >
                    <div class="event-content">
                        <div class="event-title">{{ event.title }}</div>
                        <div v-if="event.description" class="event-description">
                            {{ event.description }}
                        </div>
                    </div>
                    <div class="event-status">
                        <span v-if="event.state === 'done'" class="event-done-icon">✓</span>
                        <div class="event-priority">{{ getPriorityLabel(event.priority) }}</div>
                    </div>
                </div>
            </div>
        </div>


        <!-- 时间轴区域 -->
        <div class="timeline-section">
            <div class="timeline-container">
                <!-- 时间轴 -->
                <div class="time-axis">
                    <div
                        v-for="hour in 24"
                        :key="hour - 1"
                        :class="[
                            'time-slot',
                            { 'current-hour': isCurrentHour(hour - 1) }
                        ]"
                    >
                        <div class="time-label">{{ formatHour(hour - 1) }}</div>
                    </div>
                </div>

                <!-- 事件区域 -->
                <div class="events-area">
                    <!-- 小时网格 -->
                    <div
                        v-for="hour in 24"
                        :key="`hour-${hour - 1}`"
                        class="hour-block"
                        @click="handleHourClick(hour - 1)"
                    >
                        <!-- 当前时间指示线 -->
                        <div 
                            v-if="isCurrentHour(hour - 1) && isToday"
                            class="current-time-line"
                            :style="{ top: getCurrentTimePosition() + 'px' }"
                        >
                            <div class="time-dot"></div>
                            <div class="time-line"></div>
                        </div>
                    </div>
                    
                    <!-- 所有定时事件 - 绝对定位，连续显示 -->
                    <div
                        v-for="event in timedEventsWithLayout"
                        :key="event.id"
                        :class="[
                            'timed-event',
                            `event-${event.priority || 'default'}`,
                            { 'event-done': event.state === 'done' }
                        ]"
                        :style="{ 
                            backgroundColor: event.color,
                            height: `${getEventHeightInPixels(event)}px`,
                            top: `${getEventTopInPixels(event)}px`,
                            width: `${getEventWidth(event)}%`,
                            left: `${getEventLeft(event)}%`,
                            position: 'absolute'
                        }"
                        @click.stop="handleEventClick(event)"
                    >
                        <div class="event-time">
                            {{ getEventTimeDisplay(event) }}
                        </div>
                        <div class="event-title">{{ event.title }}</div>
                        <div v-if="event.description" class="event-description">
                            {{ event.description }}
                        </div>
                        <div class="event-actions">
                            <span v-if="event.state === 'done'" class="event-done-icon">✓</span>
                            <span class="event-priority">{{ getPriorityLabel(event.priority) }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 无时间任务区域 -->
        <div v-if="noTimeEvents.length > 0" class="no-time-section">
            <div class="section-header">
                <h3>其他任务</h3>
                <span class="task-count">{{ noTimeEvents.length }}项</span>
            </div>
            <div class="no-time-events">
                <div
                    v-for="event in noTimeEvents"
                    :key="event.id"
                    :class="[
                        'no-time-event',
                        `event-${event.priority || 'default'}`,
                        { 'event-done': event.state === 'done' }
                    ]"
                    :style="{ borderLeftColor: event.color }"
                    @click="handleEventClick(event)"
                >
                    <div class="event-content">
                        <div class="event-title">{{ event.title }}</div>
                        <div v-if="event.description" class="event-description">
                            {{ event.description }}
                        </div>
                    </div>
                    <div class="event-meta">
                        <span v-if="event.state === 'done'" class="event-done-icon">✓</span>
                        <div class="event-priority">{{ getPriorityLabel(event.priority) }}</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 空状态 -->
        <div v-if="dayEvents.length === 0" class="empty-state">
            <div class="empty-icon">📅</div>
            <div class="empty-title">今天暂无任务</div>
            <div class="empty-description">点击时间段添加新任务</div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue'
import { getWeekdayName, isToday as checkIsToday } from '../utils'
import type { CalendarEvent } from '../types'

interface Props {
    currentDate: Date
    events: CalendarEvent[]
}

interface Emits {
    (e: 'hour-click', hour: number): void
    (e: 'event-click', event: CalendarEvent): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// 检查是否是今天
const isToday = computed(() => {
    return checkIsToday(props.currentDate)
})

// 获取当天的事件
const dayEvents = computed(() => {
    // 使用本地时区的日期字符串，确保与事件日期格式一致
    const year = props.currentDate.getFullYear()
    const month = String(props.currentDate.getMonth() + 1).padStart(2, '0')
    const day = String(props.currentDate.getDate()).padStart(2, '0')
    const dateString = `${year}-${month}-${day}`
    
    console.log('Day View Debug - Current Date:', dateString)
    console.log('Day View Debug - Current Date Object:', props.currentDate)
    console.log('Day View Debug - All Events:', props.events.map(e => ({
        title: e.title,
        startDate: e.startDate,
        endDate: e.endDate,
        startTime: e.startTime,
        endTime: e.endTime,
        allDay: e.allDay
    })))
    
    const filtered = props.events.filter(event => {
        const matchesDate = event.startDate === dateString || 
                           (event.endDate && dateString >= event.startDate && dateString <= event.endDate)
        
        console.log('Event date check:', {
            eventTitle: event.title,
            eventStartDate: event.startDate,
            eventEndDate: event.endDate,
            currentDate: dateString,
            matches: matchesDate
        })
        
        return matchesDate
    })
    
    console.log('Day View Debug - Filtered Events:', filtered.length, filtered)
    
    return filtered
})

// 全天事件
const allDayEvents = computed(() => {
    return dayEvents.value.filter(event => event.allDay)
})

// 定时事件
const timedEvents = computed(() => {
    const timed = dayEvents.value.filter(event => !event.allDay && event.startTime)
    console.log('Timed Events:', timed.map(e => ({
        title: e.title,
        startTime: e.startTime,
        endTime: e.endTime,
        allDay: e.allDay
    })))
    return timed
})

// 定时事件（包含布局信息和增强颜色）
const timedEventsWithLayout = computed(() => {
    return timedEvents.value.map(event => {
        const columnInfo = eventColumnMap.value.get(event.id)
        if (columnInfo) {
            // 使用增强颜色为重叠任务提供更好的视觉区分
            const enhancedColor = getEnhancedEventColor(event, columnInfo.columnIndex)
            return {
                ...event,
                columnIndex: columnInfo.columnIndex,
                totalColumns: columnInfo.totalColumns,
                isOverlapping: columnInfo.totalColumns > 1,
                color: enhancedColor // 覆盖原始颜色
            }
        }
        return event
    })
})

// 无具体时间的非全天事件（没有设置具体时间但也不是全天事件）
const noTimeEvents = computed(() => {
    return dayEvents.value.filter(event => !event.allDay && !event.startTime)
})

// 为事件生成增强的颜色区分
function getEnhancedEventColor(event: any, columnIndex: number): string {
    const baseColor = event.color
    
    console.log('Color enhancement for event:', {
        title: event.title,
        baseColor: baseColor,
        columnIndex: columnIndex,
        isOverlapping: columnIndex > 0
    })
    
    // 如果是重叠任务，提供明显的颜色变化
    if (columnIndex > 0) {
        // 使用更简单直接的颜色变体
        const colorVariations = [
            '#ef4444', // 红色
            '#f97316', // 橙色
            '#eab308', // 黄色
            '#22c55e', // 绿色
            '#3b82f6', // 蓝色
            '#8b5cf6', // 紫色
            '#ec4899', // 粉色
            '#06b6d4', // 青色
        ]
        const enhancedColor = colorVariations[columnIndex % colorVariations.length]
        
        console.log('Enhanced color:', {
            title: event.title,
            columnIndex: columnIndex,
            originalColor: baseColor,
            enhancedColor: enhancedColor
        })
        
        return enhancedColor
    }
    
    return baseColor
}

// 调整颜色亮度
function adjustColorBrightness(hex: string, percent: number): string {
    const num = parseInt(hex.replace("#", ""), 16)
    const amt = Math.round(2.55 * percent)
    const R = Math.min(255, Math.max(0, (num >> 16) + amt))
    const G = Math.min(255, Math.max(0, (num >> 8 & 0x00FF) + amt))
    const B = Math.min(255, Math.max(0, (num & 0x0000FF) + amt))
    return "#" + ((R << 16) | (G << 8) | B).toString(16).padStart(6, '0')
}

// 调整颜色饱和度
function adjustColorSaturation(hex: string, percent: number): string {
    const hsl = hexToHsl(hex)
    hsl.s = Math.min(100, Math.max(0, hsl.s + percent))
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

    if (max !== min) {
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


// 检查是否是当前小时
function isCurrentHour(hour: number): boolean {
    if (!isToday.value) return false
    const now = new Date()
    return now.getHours() === hour
}

// 获取某小时的事件并处理重叠
function getEventsForHour(hour: number): CalendarEvent[] {
    const events = timedEvents.value.filter(event => {
        if (!event.startTime) return false
        const startHour = parseInt(event.startTime.split(':')[0])
        let endHour: number
        
        if (event.endTime) {
            endHour = parseInt(event.endTime.split(':')[0])
            // 如果结束时间是第二天的，需要考虑跨天情况
            if (endHour < startHour) {
                endHour += 24
            }
        } else {
            endHour = startHour + 1
        }
        
        const isInHour = hour >= startHour && hour < endHour
        
        return isInHour
    })
    
    // 使用全局的列分配，确保任务在整个时间段内保持一致的位置
    return assignGlobalEventColumns(events)
}

// 全局事件列分配映射
const eventColumnMap = computed(() => {
    const map = new Map<string, { columnIndex: number, totalColumns: number }>()
    
    if (timedEvents.value.length === 0) return map
    
    // 按开始时间排序所有定时事件
    const sortedEvents = [...timedEvents.value].sort((a, b) => {
        const timeA = a.startTime || '00:00'
        const timeB = b.startTime || '00:00'
        return timeA.localeCompare(timeB)
    })
    
    // 找到所有重叠的事件组
    const overlappingGroups: CalendarEvent[][] = []
    let currentGroup: CalendarEvent[] = []
    
    for (const event of sortedEvents) {
        if (currentGroup.length === 0) {
            currentGroup.push(event)
        } else {
            // 检查当前事件是否与组中任何事件重叠
            const hasOverlap = currentGroup.some(groupEvent => eventsOverlap(event, groupEvent))
            
            if (hasOverlap) {
                currentGroup.push(event)
            } else {
                // 当前组完成，开始新组
                if (currentGroup.length > 0) {
                    overlappingGroups.push([...currentGroup])
                }
                currentGroup = [event]
            }
        }
    }
    
    // 添加最后一组
    if (currentGroup.length > 0) {
        overlappingGroups.push(currentGroup)
    }
    
    // 为每组中的事件分配列
    overlappingGroups.forEach(group => {
        const totalColumns = group.length
        group.forEach((event, index) => {
            map.set(event.id, {
                columnIndex: index,
                totalColumns: totalColumns
            })
        })
    })
    
    return map
})

// 检查两个事件是否重叠
function eventsOverlap(event1: CalendarEvent, event2: CalendarEvent): boolean {
    if (!event1.startTime || !event2.startTime) return false
    
    const start1 = getEventMinutes(event1.startTime)
    const end1 = getEventMinutes(event1.endTime || event1.startTime) + (event1.endTime ? 0 : 60)
    const start2 = getEventMinutes(event2.startTime)
    const end2 = getEventMinutes(event2.endTime || event2.startTime) + (event2.endTime ? 0 : 60)
    
    const overlaps = start1 < end2 && start2 < end1
    
    console.log('Overlap check:', {
        event1: { title: event1.title, start: start1, end: end1 },
        event2: { title: event2.title, start: start2, end: end2 },
        overlaps: overlaps
    })
    
    return overlaps
}

// 使用全局列分配
function assignGlobalEventColumns(events: CalendarEvent[]): CalendarEvent[] {
    return events.map(event => {
        const columnInfo = eventColumnMap.value.get(event.id)
        if (columnInfo) {
            return {
                ...event,
                columnIndex: columnInfo.columnIndex,
                totalColumns: columnInfo.totalColumns,
                isOverlapping: columnInfo.totalColumns > 1
            }
        }
        return event
    })
}

// 检查事件是否与列中的其他事件有时间冲突
function hasTimeConflict(event: CalendarEvent, columnEvents: CalendarEvent[]): boolean {
    const eventStart = getEventMinutes(event.startTime || '00:00')
    const eventEnd = getEventMinutes(event.endTime || event.startTime || '00:00') + 60 // 默认1小时
    
    return columnEvents.some(existingEvent => {
        const existingStart = getEventMinutes(existingEvent.startTime || '00:00')
        const existingEnd = getEventMinutes(existingEvent.endTime || existingEvent.startTime || '00:00') + 60
        
        // 检查时间段是否重叠
        return eventStart < existingEnd && eventEnd > existingStart
    })
}

// 将时间字符串转换为分钟数
function getEventMinutes(timeString: string): number {
    const [hours, minutes] = timeString.split(':').map(Number)
    return hours * 60 + minutes
}

// 格式化小时
function formatHour(hour: number): string {
    return `${hour.toString().padStart(2, '0')}:00`
}

// 获取事件时间显示
function getEventTimeDisplay(event: CalendarEvent): string {
    if (!event.startTime) return '全天'
    if (event.endTime) {
        return `${event.startTime} - ${event.endTime}`
    }
    return event.startTime
}

// 计算事件在像素坐标中的高度
function getEventHeightInPixels(event: CalendarEvent): number {
    if (!event.startTime) return 60
    
    const [startHour, startMinute] = event.startTime.split(':').map(Number)
    let endHour: number, endMinute: number
    
    if (event.endTime) {
        [endHour, endMinute] = event.endTime.split(':').map(Number)
    } else {
        // 默认1小时
        endHour = startHour + 1
        endMinute = startMinute
    }
    
    const durationInMinutes = (endHour * 60 + endMinute) - (startHour * 60 + startMinute)
    const pixelsPerMinute = 1 // 每分钟1px，每小时60px
    
    return Math.max(durationInMinutes * pixelsPerMinute, 30) // 最小高度30px
}

// 计算事件在像素坐标中的顶部位置
function getEventTopInPixels(event: CalendarEvent): number {
    if (!event.startTime) return 0
    
    const [startHour, startMinute] = event.startTime.split(':').map(Number)
    const totalMinutesFromMidnight = startHour * 60 + startMinute
    const pixelsPerMinute = 1 // 每分钟1px
    
    return totalMinutesFromMidnight * pixelsPerMinute
}

// 计算事件顶部位置
function getEventTop(event: CalendarEvent): number {
    if (!event.startTime) return 0
    
    const [hour, minute] = event.startTime.split(':').map(Number)
    const minutesFromHourStart = minute
    const pixelsPerMinute = 60 / 60 // 每小时60px，每分钟1px
    
    return minutesFromHourStart * pixelsPerMinute
}

// 计算特定小时内事件的顶部位置
function getEventTopForHour(event: CalendarEvent, hour: number): number {
    if (!event.startTime) return 0
    
    const [startHour, startMinute] = event.startTime.split(':').map(Number)
    
    // 如果事件开始于当前小时，使用分钟偏移
    if (startHour === hour) {
        return startMinute // 每分钟1px
    }
    
    // 如果事件开始于之前的小时，则从该小时的开始位置开始
    return 0
}

// 计算特定小时内事件的高度
function getEventHeightForHour(event: CalendarEvent, hour: number): number {
    if (!event.startTime) return 60
    
    const [startHour, startMinute] = event.startTime.split(':').map(Number)
    
    let endHour: number
    let endMinute: number
    
    if (event.endTime) {
        [endHour, endMinute] = event.endTime.split(':').map(Number)
    } else {
        // 默认1小时
        endHour = startHour + 1
        endMinute = startMinute
    }
    
    // 计算在当前小时内的部分
    let hourStartMinute = 0
    let hourEndMinute = 60
    
    // 如果事件开始于当前小时
    if (startHour === hour) {
        hourStartMinute = startMinute
    }
    
    // 如果事件结束于当前小时
    if (endHour === hour) {
        hourEndMinute = endMinute
    } else if (endHour < hour) {
        // 事件已经结束，不应该在这个小时显示
        return 0
    }
    
    const heightInThisHour = hourEndMinute - hourStartMinute
    return Math.max(heightInThisHour, 15) // 最小高度15px
}

// 计算事件宽度（百分比）
function getEventWidth(event: any): number {
    if (event.isOverlapping && event.totalColumns > 1) {
        // 为重叠任务添加间距：总可用宽度90%，任务间间距2%
        const totalGaps = (event.totalColumns - 1) * 2 // 总间距宽度
        const availableForTasks = 90 - totalGaps // 任务可用的总宽度
        const width = availableForTasks / event.totalColumns // 每个任务的宽度
        
        console.log(`Event ${event.title} width calculation:`, {
            totalColumns: event.totalColumns,
            columnIndex: event.columnIndex,
            totalGaps: totalGaps,
            availableForTasks: availableForTasks,
            width: width
        })
        return width
    }
    return 90 // 单个事件占90%宽度
}

// 计算事件左偏移（百分比）
function getEventLeft(event: any): number {
    if (event.isOverlapping && event.totalColumns > 1) {
        const totalGaps = (event.totalColumns - 1) * 2
        const availableForTasks = 90 - totalGaps
        const taskWidth = availableForTasks / event.totalColumns
        const gapWidth = 2 // 每个间距2%
        
        // 左偏移 = 基础偏移 + (任务宽度 + 间距) * 任务索引
        const leftOffset = 5 + (taskWidth + gapWidth) * event.columnIndex
        
        console.log(`Event ${event.title} left calculation:`, {
            totalColumns: event.totalColumns,
            columnIndex: event.columnIndex,
            taskWidth: taskWidth,
            gapWidth: gapWidth,
            leftOffset: leftOffset
        })
        return leftOffset
    }
    return 5 // 单个事件左偏移5%
}

// 获取当前时间位置
function getCurrentTimePosition(): number {
    if (!isToday.value) return 0
    
    const now = new Date()
    const minutes = now.getMinutes()
    const pixelsPerMinute = 60 / 60 // 每小时60px，每分钟1px
    
    return minutes * pixelsPerMinute
}

// 获取优先级标签
function getPriorityLabel(priority?: string): string {
    switch (priority) {
        case 'urgent':
            return '紧急'
        case 'high':
            return '高'
        case 'medium':
            return '中'
        case 'low':
            return '低'
        default:
            return ''
    }
}

// 处理小时点击
function handleHourClick(hour: number) {
    emit('hour-click', hour)
}

// 处理事件点击
function handleEventClick(event: CalendarEvent) {
    emit('event-click', event)
}
</script>

<style scoped>
.day-view {
    background: #ffffff;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    height: 100vh;
    display: flex;
    flex-direction: column;
}

.day-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: #ffffff;
    flex-shrink: 0; /* 防止头部被压缩 */
    z-index: 10; /* 确保头部在顶层 */
}

.date-info {
    text-align: left;
}

.weekday-name {
    font-size: 14px;
    opacity: 0.9;
    margin-bottom: 4px;
}

.date-number {
    font-size: 48px;
    font-weight: 700;
    line-height: 1;
    margin-bottom: 4px;
}

.date-number.today {
    color: #fbbf24;
}

.month-year {
    font-size: 14px;
    opacity: 0.9;
}


.all-day-section {
    border-bottom: 1px solid #e2e8f0;
    background: #f8fafc;
    flex-shrink: 0; /* 防止全天事件区域被压缩 */
}

.section-header {
    padding: 12px 20px 8px;
    border-bottom: 1px solid #e2e8f0;
}

.section-header h3 {
    font-size: 14px;
    font-weight: 600;
    color: #374151;
    margin: 0;
}

.all-day-events {
    padding: 12px 20px;
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.all-day-event {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 16px;
    border-radius: 8px;
    color: #ffffff;
    cursor: pointer;
    transition: all 0.2s;
}

.all-day-event:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.event-content {
    flex: 1;
}

.event-title {
    font-size: 14px;
    font-weight: 600;
    margin-bottom: 2px;
}

.event-description {
    font-size: 12px;
    opacity: 0.9;
}

.event-status {
    display: flex;
    align-items: center;
    gap: 8px;
}

.event-priority {
    font-size: 10px;
    padding: 2px 6px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 12px;
}

.timeline-section {
    flex: 1;
    overflow-y: auto;
    min-height: 0; /* 允许flex子元素收缩 */
}

.timeline-container {
    display: flex;
    min-height: 100%;
}

.time-axis {
    width: 80px;
    border-right: 1px solid #e2e8f0;
    background: #f8fafc;
}

.time-slot {
    height: 60px;
    border-bottom: 1px solid #f1f5f9;
    position: relative;
}

.time-slot.current-hour {
    background: #fef3c7;
}

.time-label {
    position: absolute;
    top: -8px;
    right: 8px;
    font-size: 11px;
    color: #6b7280;
    background: #f8fafc;
    padding: 2px 4px;
}

.events-area {
    flex: 1;
    position: relative;
    min-height: 1440px; /* 24小时 * 60px - 最小高度而不是固定高度 */
}

.hour-block {
    height: 60px;
    border-bottom: 1px solid #f1f5f9;
    position: relative;
    cursor: pointer;
    transition: all 0.2s;
}

.hour-block:hover {
    background: #f8fafc;
}

.timed-event {
    position: absolute;
    padding: 6px 8px;
    border-radius: 4px;
    color: #ffffff;
    cursor: pointer;
    z-index: 1;
    min-height: 30px;
    transition: all 0.2s;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    overflow: hidden;
}

.timed-event:hover {
    transform: scale(1.02);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    z-index: 10;
    border: 2px solid rgba(255, 255, 255, 0.5);
}

.timed-event .event-time {
    font-size: 10px;
    opacity: 0.9;
    margin-bottom: 2px;
    line-height: 1.2;
}

.timed-event .event-title {
    font-size: 11px;
    font-weight: 600;
    margin-bottom: 1px;
    line-height: 1.2;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.timed-event .event-description {
    font-size: 9px;
    opacity: 0.9;
    margin-bottom: 2px;
    line-height: 1.2;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.event-actions {
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.event-done-icon {
    font-size: 12px;
}

.event-done {
    opacity: 0.7;
    text-decoration: line-through;
}

.current-time-line {
    position: absolute;
    left: 0;
    right: 0;
    z-index: 3;
    display: flex;
    align-items: center;
}

.time-dot {
    width: 8px;
    height: 8px;
    background: #ef4444;
    border-radius: 50%;
    margin-left: 4px;
}

.time-line {
    flex: 1;
    height: 2px;
    background: #ef4444;
    margin-left: 4px;
    margin-right: 8px;
}

.no-time-section {
    border-top: 1px solid #e2e8f0;
    background: #f8fafc;
    padding: 16px 20px;
    flex-shrink: 0; /* 防止无时间任务区域被压缩 */
}

.no-time-section .section-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 12px;
    padding: 0;
}

.no-time-section .section-header h3 {
    font-size: 14px;
    font-weight: 600;
    color: #374151;
    margin: 0;
}

.task-count {
    font-size: 12px;
    color: #6b7280;
    background: #e5e7eb;
    padding: 2px 8px;
    border-radius: 12px;
}

.no-time-events {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.no-time-event {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 16px;
    background: #ffffff;
    border-radius: 6px;
    border: 1px solid #e5e7eb;
    border-left: 4px solid;
    cursor: pointer;
    transition: all 0.2s;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.no-time-event:hover {
    background: #f9fafb;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    transform: translateX(2px);
}

.no-time-event.event-done {
    opacity: 0.7;
}

.no-time-event.event-done .event-title {
    text-decoration: line-through;
}

.no-time-event .event-content {
    flex: 1;
}

.no-time-event .event-title {
    font-size: 14px;
    font-weight: 500;
    color: #374151;
    margin-bottom: 2px;
}

.no-time-event .event-description {
    font-size: 12px;
    color: #6b7280;
    line-height: 1.4;
}

.no-time-event .event-meta {
    display: flex;
    align-items: center;
    gap: 8px;
}

.no-time-event .event-done-icon {
    color: #22c55e;
    font-weight: bold;
    font-size: 14px;
}

.no-time-event .event-priority {
    font-size: 10px;
    padding: 2px 6px;
    border-radius: 8px;
    background: #f3f4f6;
    color: #6b7280;
    font-weight: 500;
}

.empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 60px 20px;
    text-align: center;
    flex: 1;
}

.empty-icon {
    font-size: 48px;
    margin-bottom: 16px;
}

.empty-title {
    font-size: 18px;
    font-weight: 600;
    color: #374151;
    margin-bottom: 8px;
}

.empty-description {
    font-size: 14px;
    color: #6b7280;
}

/* 优先级颜色 */
.event-urgent {
    background-color: #ef4444 !important;
}

.event-high {
    background-color: #f97316 !important;
}

.event-medium {
    background-color: #eab308 !important;
}

.event-low {
    background-color: #22c55e !important;
}

.event-default {
    background-color: #6b7280 !important;
}

/* 响应式设计 */
@media (max-width: 768px) {
    .day-header {
        padding: 16px;
    }
    
    .date-number {
        font-size: 36px;
    }
    
    
    .time-axis {
        width: 60px;
    }
    
    .all-day-events {
        padding: 8px 16px;
    }
    
    .no-time-section {
        padding: 12px 16px;
    }
    
    .no-time-event {
        padding: 10px 12px;
    }
    
    .no-time-event .event-title {
        font-size: 13px;
    }
    
    .no-time-event .event-description {
        font-size: 11px;
    }
}
</style>