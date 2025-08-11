<template>
    <div class="week-view">
        <!-- 时间轴和日期头部 -->
        <div class="week-header">
            <div class="time-column-header"></div>
            <div class="days-header">
                <div
                    v-for="day in weekDays"
                    :key="day.date.getTime()"
                    :class="[
                        'day-header',
                        {
                            'today': day.isToday,
                            'selected': isSelected(day.date)
                        }
                    ]"
                    @click="handleDayClick(day.date)"
                >
                    <div class="day-name">{{ getWeekdayName(day.date.getDay(), true) }}</div>
                    <div class="day-number">{{ day.day }}</div>
                </div>
            </div>
        </div>

        <!-- 全天事件区域 -->
        <div class="all-day-section" v-if="hasAllDayEvents">
            <div class="time-column-label">
                <span>全天</span>
            </div>
            <div class="all-day-events">
                <div
                    v-for="day in weekDays"
                    :key="`allday-${day.date.getTime()}`"
                    class="all-day-column"
                >
                    <div
                        v-for="event in getAllDayEventsForDay(day)"
                        :key="event.id"
                        :class="[
                            'all-day-event',
                            `event-${event.priority || 'default'}`,
                            { 'event-done': event.state === 'done' }
                        ]"
                        :style="{ 
                            backgroundColor: event.color,
                            width: event.isOverlapping ? `${90/event.totalColumns}%` : '100%',
                            marginLeft: event.isOverlapping ? `${(90/event.totalColumns) * event.columnIndex}%` : '0%'
                        }"
                        @click="handleEventClick(event)"
                        :title="event.title + (event.description ? ' - ' + event.description : '')"
                    >
                        {{ event.title }}
                        <span v-if="event.state === 'done'" class="event-done-icon">✓</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- 小时网格区域 -->
        <div class="hours-grid-container">
            <div class="time-column">
                <div
                    v-for="hour in 24"
                    :key="hour - 1"
                    class="time-slot"
                >
                    {{ formatHour(hour - 1) }}
                </div>
            </div>
            
            <div class="hours-grid">
                <div
                    v-for="day in weekDays"
                    :key="`hours-${day.date.getTime()}`"
                    class="day-column"
                >
                    <div
                        v-for="hour in day.hours"
                        :key="hour.hour"
                        :class="[
                            'hour-slot',
                            { 'current-hour': isCurrentHour(day.date, hour.hour) }
                        ]"
                        @click="handleHourClick(day.date, hour.hour)"
                    >
                        <!-- 时间段内的事件 -->
                        <div
                            v-for="event in getTimedEventsForHour(hour)"
                            :key="event.id"
                            :class="[
                                'timed-event',
                                `event-${event.priority || 'default'}`,
                                { 'event-done': event.state === 'done' }
                            ]"
                            :style="{ 
                                backgroundColor: event.color,
                                height: getEventHeight(event) + 'px',
                                width: `${getEventWidth(event)}%`,
                                left: `${getEventLeft(event)}%`,
                                top: getEventTopOffset(event) + 'px'
                            }"
                            @click.stop="handleEventClick(event)"
                            :title="event.title + (event.description ? ' - ' + event.description : '')"
                        >
                            <div class="event-time">
                                {{ getEventTimeDisplay(event) }}
                            </div>
                            <div class="event-title">
                                {{ event.title }}
                                <span v-if="event.state === 'done'" class="event-done-icon">✓</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue'
import { getWeekViewDates, getWeekdayName, isSameDay } from '../utils'
import type { CalendarEvent, WeekDay, CalendarHour } from '../types'

interface Props {
    currentDate: Date
    selectedDate?: Date | null
    events: CalendarEvent[]
}

interface Emits {
    (e: 'day-click', date: Date): void
    (e: 'hour-click', date: Date, hour: number): void
    (e: 'event-click', event: CalendarEvent): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// 获取周视图数据
const weekDays = computed(() => {
    return getWeekViewDates(props.currentDate, props.events)
})

// 检查是否有全天事件
const hasAllDayEvents = computed(() => {
    return weekDays.value.some(day => 
        day.events.some(event => event.allDay)
    )
})

// 检查日期是否被选中
function isSelected(date: Date): boolean {
    return props.selectedDate ? isSameDay(date, props.selectedDate) : false
}

// 检查是否是当前小时
function isCurrentHour(date: Date, hour: number): boolean {
    const now = new Date()
    return isSameDay(date, now) && now.getHours() === hour
}

// 获取某天的全天事件并处理重叠
function getAllDayEventsForDay(day: WeekDay): CalendarEvent[] {
    const events = day.events.filter(event => event.allDay)
    
    // 简单处理全天事件重叠
    return events.map((event, index) => ({
        ...event,
        columnIndex: index,
        totalColumns: events.length,
        isOverlapping: events.length > 1,
        color: getEnhancedEventColor(event, index)
    }))
}

// 全局事件列分配映射（类似日视图）
const eventColumnMap = computed(() => {
    const map = new Map<string, { columnIndex: number, totalColumns: number }>()
    
    // 为每一天分别处理重叠事件
    weekDays.value.forEach(day => {
        const dayTimedEvents = day.events.filter(event => !event.allDay && event.startTime)
        
        if (dayTimedEvents.length === 0) return
        
        // 按开始时间排序
        const sortedEvents = [...dayTimedEvents].sort((a, b) => {
            const timeA = a.startTime || '00:00'
            const timeB = b.startTime || '00:00'
            return timeA.localeCompare(timeB)
        })
        
        // 找到重叠事件组
        const overlappingGroups: CalendarEvent[][] = []
        let currentGroup: CalendarEvent[] = []
        
        for (const event of sortedEvents) {
            if (currentGroup.length === 0) {
                currentGroup.push(event)
            } else {
                const hasOverlap = currentGroup.some(groupEvent => eventsOverlap(event, groupEvent))
                
                if (hasOverlap) {
                    currentGroup.push(event)
                } else {
                    if (currentGroup.length > 0) {
                        overlappingGroups.push([...currentGroup])
                    }
                    currentGroup = [event]
                }
            }
        }
        
        if (currentGroup.length > 0) {
            overlappingGroups.push(currentGroup)
        }
        
        // 为每组分配列
        overlappingGroups.forEach(group => {
            const totalColumns = group.length
            group.forEach((event, index) => {
                map.set(event.id, {
                    columnIndex: index,
                    totalColumns: totalColumns
                })
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
    
    return start1 < end2 && start2 < end1
}

// 将时间字符串转换为分钟数
function getEventMinutes(timeString: string): number {
    const [hours, minutes] = timeString.split(':').map(Number)
    return hours * 60 + minutes
}

// 获取某小时的定时事件（只获取在该小时开始的事件，避免重复）
function getTimedEventsForHour(hour: CalendarHour): CalendarEvent[] {
    const events = hour.events.filter(event => {
        if (!event.startTime || event.allDay) return false
        
        // 只显示在当前小时开始的事件
        const startHour = parseInt(event.startTime.split(':')[0])
        return startHour === hour.hour
    })
    
    // 应用全局列分配
    return events.map(event => {
        const columnInfo = eventColumnMap.value.get(event.id)
        if (columnInfo) {
            return {
                ...event,
                columnIndex: columnInfo.columnIndex,
                totalColumns: columnInfo.totalColumns,
                isOverlapping: columnInfo.totalColumns > 1,
                color: getEnhancedEventColor(event, columnInfo.columnIndex)
            }
        }
        return event
    })
}

// 为事件生成增强的颜色区分
function getEnhancedEventColor(event: any, columnIndex: number): string {
    const baseColor = event.color
    
    // 如果是重叠任务，提供明显的颜色变化
    if (columnIndex > 0) {
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
        return colorVariations[columnIndex % colorVariations.length]
    }
    
    return baseColor
}

// 格式化小时显示
function formatHour(hour: number): string {
    return `${hour.toString().padStart(2, '0')}:00`
}

// 获取事件时间显示
function getEventTimeDisplay(event: CalendarEvent): string {
    if (!event.startTime) return ''
    if (event.endTime) {
        return `${event.startTime} - ${event.endTime}`
    }
    return event.startTime
}

// 计算事件高度（基于持续时间，跨越完整时间段）
function getEventHeight(event: CalendarEvent): number {
    if (!event.startTime) return 40
    
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
    const pixelsPerMinute = 40 / 60 // 每小时40px，每分钟约0.67px
    
    return Math.max(durationInMinutes * pixelsPerMinute, 20) // 最小高度20px
}

// 计算事件在小时网格中的顶部位置偏移
function getEventTopOffset(event: CalendarEvent): number {
    if (!event.startTime) return 0
    
    const [startHour, startMinute] = event.startTime.split(':').map(Number)
    const minutesOffset = startMinute * (40 / 60) // 分钟偏移，每分钟约0.67px
    
    return minutesOffset
}

// 计算事件宽度（百分比）
function getEventWidth(event: any): number {
    if (event.isOverlapping && event.totalColumns > 1) {
        // 为重叠任务添加间距：总可用宽度90%，任务间间距2%
        const totalGaps = (event.totalColumns - 1) * 2 // 总间距宽度
        const availableForTasks = 90 - totalGaps // 任务可用的总宽度
        const width = availableForTasks / event.totalColumns // 每个任务的宽度
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
        return leftOffset
    }
    return 5 // 单个事件左偏移5%
}

// 处理日期点击
function handleDayClick(date: Date) {
    emit('day-click', date)
}

// 处理小时点击
function handleHourClick(date: Date, hour: number) {
    emit('hour-click', date, hour)
}

// 处理事件点击
function handleEventClick(event: CalendarEvent) {
    emit('event-click', event)
}
</script>

<style scoped>
.week-view {
    background: #ffffff;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    height: 100vh;
    display: flex;
    flex-direction: column;
}

.week-header {
    display: flex;
    border-bottom: 1px solid #e2e8f0;
    background: #f8fafc;
    flex-shrink: 0; /* 防止头部被压缩 */
    z-index: 10; /* 确保头部在顶层 */
}

.time-column-header {
    width: 60px;
    border-right: 1px solid #e2e8f0;
}

.days-header {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    flex: 1;
}

.day-header {
    padding: 12px 8px;
    text-align: center;
    cursor: pointer;
    border-right: 1px solid #e2e8f0;
    transition: all 0.2s;
}

.day-header:hover {
    background: #e2e8f0;
}

.day-header.today {
    background: #eff6ff;
}

.day-header.selected {
    background: #dbeafe;
    box-shadow: inset 0 0 0 2px #3b82f6;
}

.day-name {
    font-size: 12px;
    color: #6b7280;
    margin-bottom: 2px;
}

.day-number {
    font-size: 18px;
    font-weight: 600;
    color: #1f2937;
}

.day-header.today .day-number {
    background: #3b82f6;
    color: #ffffff;
    border-radius: 50%;
    width: 28px;
    height: 28px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
}

.all-day-section {
    display: flex;
    border-bottom: 1px solid #e2e8f0;
    background: #fafbfc;
    flex-shrink: 0; /* 防止全天事件区域被压缩 */
}

.time-column-label {
    width: 60px;
    padding: 8px 4px;
    font-size: 10px;
    color: #6b7280;
    text-align: center;
    border-right: 1px solid #e2e8f0;
    display: flex;
    align-items: center;
    justify-content: center;
}

.all-day-events {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    flex: 1;
}

.all-day-column {
    padding: 4px;
    border-right: 1px solid #e2e8f0;
    min-height: 40px;
}

.all-day-event {
    padding: 2px 6px;
    margin: 1px 0;
    border-radius: 4px;
    font-size: 12px;
    color: #ffffff;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: space-between;
    transition: all 0.2s;
}

.all-day-event:hover {
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.hours-grid-container {
    display: flex;
    flex: 1;
    overflow-y: auto;
    min-height: 0; /* 允许flex子元素收缩 */
}

.time-column {
    width: 60px;
    border-right: 1px solid #e2e8f0;
}

.time-slot {
    height: 40px;
    padding: 4px;
    font-size: 10px;
    color: #6b7280;
    text-align: center;
    border-bottom: 1px solid #f1f5f9;
    display: flex;
    align-items: flex-start;
    justify-content: center;
}

.hours-grid {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    flex: 1;
}

.day-column {
    border-right: 1px solid #e2e8f0;
}

.hour-slot {
    height: 40px;
    border-bottom: 1px solid #f1f5f9;
    position: relative;
    cursor: pointer;
    transition: all 0.2s;
}

.hour-slot:hover {
    background: #f8fafc;
}

.hour-slot.current-hour {
    background: #fef3c7;
}

.timed-event {
    position: absolute;
    padding: 2px 4px;
    border-radius: 4px;
    font-size: 11px;
    color: #ffffff;
    cursor: pointer;
    z-index: 1;
    min-height: 20px;
    transition: all 0.2s;
    /* top, left, width, height 都通过内联样式动态设置 */
}

.timed-event:hover {
    transform: translateX(2px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    z-index: 2;
}

.event-time {
    font-size: 9px;
    opacity: 0.9;
    margin-bottom: 1px;
}

.event-title {
    font-weight: 500;
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.event-done-icon {
    font-size: 10px;
    margin-left: 2px;
}

.event-done {
    opacity: 0.7;
    text-decoration: line-through;
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
    .time-column-header,
    .time-column {
        width: 50px;
    }
    
    .time-slot {
        font-size: 9px;
    }
    
    .day-name {
        font-size: 10px;
    }
    
    .day-number {
        font-size: 14px;
    }
    
    .all-day-event,
    .timed-event {
        font-size: 10px;
    }
}
</style>