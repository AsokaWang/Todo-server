<template>
    <div class="month-view">
        <!-- 星期表头 -->
        <div class="weekday-header">
            <div v-for="weekday in weekdays" :key="weekday" class="weekday-cell">
                {{ weekday }}
            </div>
        </div>

        <!-- 日期网格 -->
        <div class="date-grid">
            <div
                v-for="(date, index) in dates"
                :key="index"
                :class="[
                    'date-cell',
                    {
                        'today': date.isToday,
                        'selected': isSelected(date.date),
                        'other-month': !date.isCurrentMonth,
                        'has-events': date.events.length > 0
                    }
                ]"
                @click="handleDateClick(date)"
            >
                <!-- 日期数字 -->
                <div class="date-number">
                    {{ date.day }}
                </div>

                <!-- 事件列表 -->
                <div class="events-container" v-if="date.events.length > 0">
                    <div
                        v-for="(event, eventIndex) in date.events.slice(0, maxEventsPerDay)"
                        :key="event.id"
                        :class="[
                            'event-item',
                            `event-${event.priority || 'default'}`,
                            { 'event-done': event.state === 'done' }
                        ]"
                        :style="{ 
                            backgroundColor: event.color,
                            borderColor: event.color 
                        }"
                        @click.stop="handleEventClick(event)"
                        :title="event.title + (event.description ? ' - ' + event.description : '')"
                    >
                        <span class="event-title">{{ event.title }}</span>
                        <span v-if="event.state === 'done'" class="event-done-icon">✓</span>
                    </div>

                    <!-- 更多事件提示 -->
                    <div 
                        v-if="date.events.length > maxEventsPerDay"
                        class="more-events"
                        @click.stop="handleShowMoreEvents(date)"
                    >
                        +{{ date.events.length - maxEventsPerDay }} 更多
                    </div>
                </div>

                <!-- 空状态点击区域 -->
                <div 
                    v-else
                    class="empty-date-area"
                    @click.stop="handleAddEvent(date)"
                >
                </div>
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { computed } from 'vue'
import { getMonthViewDates, getWeekdayName, isSameDay } from '../utils'
import type { CalendarDate, CalendarEvent } from '../types'

interface Props {
    currentDate: Date
    selectedDate?: Date | null
    events: CalendarEvent[]
    maxEventsPerDay?: number
}

interface Emits {
    (e: 'date-click', date: Date): void
    (e: 'event-click', event: CalendarEvent): void
    (e: 'show-more-events', date: CalendarDate): void
    (e: 'add-event', date: Date): void
}

const props = withDefaults(defineProps<Props>(), {
    maxEventsPerDay: 3
})

const emit = defineEmits<Emits>()

// 星期表头
const weekdays = ['日', '一', '二', '三', '四', '五', '六']

// 获取月视图的日期数据
const dates = computed(() => {
    const year = props.currentDate.getFullYear()
    const month = props.currentDate.getMonth() + 1
    return getMonthViewDates(year, month, props.events)
})

// 检查日期是否被选中
function isSelected(date: Date): boolean {
    return props.selectedDate ? isSameDay(date, props.selectedDate) : false
}

// 处理日期点击
function handleDateClick(date: CalendarDate) {
    emit('date-click', date.date)
}

// 处理事件点击
function handleEventClick(event: CalendarEvent) {
    emit('event-click', event)
}

// 处理显示更多事件
function handleShowMoreEvents(date: CalendarDate) {
    emit('show-more-events', date)
}

// 处理添加事件
function handleAddEvent(date: CalendarDate) {
    emit('add-event', date.date)
}
</script>

<style scoped>
.month-view {
    background: #ffffff;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.weekday-header {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    background: #f8fafc;
    border-bottom: 1px solid #e2e8f0;
}

.weekday-cell {
    padding: 12px 8px;
    text-align: center;
    font-size: 14px;
    font-weight: 600;
    color: #64748b;
}

.date-grid {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    grid-auto-rows: minmax(120px, auto);
}

.date-cell {
    position: relative;
    padding: 8px;
    border-right: 1px solid #e2e8f0;
    border-bottom: 1px solid #e2e8f0;
    background: #ffffff;
    cursor: pointer;
    transition: all 0.2s;
    min-height: 120px;
}

.date-cell:hover {
    background: #f8fafc;
}

.date-cell.today {
    background: #eff6ff;
}

.date-cell.today .date-number {
    background: #3b82f6;
    color: #ffffff;
}

.date-cell.selected {
    background: #dbeafe;
    box-shadow: inset 0 0 0 2px #3b82f6;
}

.date-cell.other-month {
    background: #f8fafc;
    color: #9ca3af;
}

.date-cell.other-month .date-number {
    color: #9ca3af;
}

.date-number {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 28px;
    height: 28px;
    font-size: 14px;
    font-weight: 500;
    color: #1f2937;
    border-radius: 50%;
    margin-bottom: 4px;
}

.events-container {
    display: flex;
    flex-direction: column;
    gap: 2px;
    flex: 1;
}

.event-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 2px 6px;
    font-size: 12px;
    color: #ffffff;
    border-radius: 4px;
    border-left: 3px solid;
    cursor: pointer;
    transition: all 0.2s;
    background-color: #6b7280;
    border-color: #6b7280;
}

.event-item:hover {
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.event-title {
    flex: 1;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    font-weight: 500;
}

.event-done-icon {
    font-size: 10px;
    margin-left: 4px;
}

.event-done {
    opacity: 0.7;
    text-decoration: line-through;
}

.event-urgent {
    background-color: #ef4444;
    border-color: #dc2626;
}

.event-high {
    background-color: #f97316;
    border-color: #ea580c;
}

.event-medium {
    background-color: #eab308;
    border-color: #ca8a04;
}

.event-low {
    background-color: #22c55e;
    border-color: #16a34a;
}

.more-events {
    padding: 2px 6px;
    font-size: 11px;
    color: #6b7280;
    background: #f3f4f6;
    border-radius: 4px;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s;
}

.more-events:hover {
    background: #e5e7eb;
    color: #374151;
}

.empty-date-area {
    flex: 1;
    min-height: 60px;
}

/* 响应式设计 */
@media (max-width: 768px) {
    .date-grid {
        grid-auto-rows: minmax(80px, auto);
    }
    
    .date-cell {
        padding: 4px;
        min-height: 80px;
    }
    
    .date-number {
        width: 24px;
        height: 24px;
        font-size: 12px;
    }
    
    .event-item {
        padding: 1px 4px;
        font-size: 10px;
    }
    
    .weekday-cell {
        padding: 8px 4px;
        font-size: 12px;
    }
}
</style>