<template>
    <view id="CalendarView" class="calendar-view">
        <!-- 日历头部 -->
        <view class="calendar-header">
            <view class="header-title">
                <text class="title-text">{{ currentTitle }}</text>
            </view>
            <view class="header-controls">
                <view class="view-switcher">
                    <text 
                        v-for="view in viewTypes" 
                        :key="view.value"
                        :class="['view-btn', { active: currentView === view.value }]"
                        @click="switchView(view.value)"
                    >
                        {{ view.label }}
                    </text>
                </view>
                <view class="nav-controls">
                    <text class="nav-btn" @click="goToPrev">‹</text>
                    <text class="nav-btn today-btn" @click="goToToday">今天</text>
                    <text class="nav-btn" @click="goToNext">›</text>
                </view>
            </view>
        </view>

        <!-- 日历内容 -->
        <scroll-view class="calendar-content" scroll-y="true">
            <!-- 月视图 -->
            <view v-if="currentView === 'month'" class="month-view">
                <!-- 星期表头 -->
                <view class="weekday-header">
                    <text v-for="day in weekdays" :key="day" class="weekday-cell">
                        {{ day }}
                    </text>
                </view>
                <!-- 日期网格 -->
                <view class="date-grid">
                    <view 
                        v-for="(date, index) in monthDates" 
                        :key="index"
                        :class="[
                            'date-cell',
                            {
                                'today': date.isToday,
                                'other-month': !date.isCurrentMonth,
                                'selected': isSelectedDate(date.date)
                            }
                        ]"
                        @click="selectDate(date.date)"
                    >
                        <text class="date-number">{{ date.day }}</text>
                        <view class="events-container" v-if="date.events.length > 0">
                            <view 
                                v-for="event in date.events.slice(0, 2)" 
                                :key="event.id"
                                :class="['event-dot', `priority-${event.priority || 'default'}`]"
                            ></view>
                            <text v-if="date.events.length > 2" class="more-events">
                                +{{ date.events.length - 2 }}
                            </text>
                        </view>
                    </view>
                </view>
            </view>

            <!-- 周视图和日视图的简化版本 -->
            <view v-else-if="currentView === 'week'" class="week-view">
                <view class="week-days">
                    <view 
                        v-for="day in weekDays" 
                        :key="day.date.getTime()"
                        :class="['week-day', { 'today': day.isToday }]"
                        @click="selectDate(day.date)"
                    >
                        <text class="day-name">{{ getWeekdayName(day.date.getDay()) }}</text>
                        <text class="day-number">{{ day.day }}</text>
                        <view class="day-events">
                            <view 
                                v-for="event in day.events.slice(0, 3)" 
                                :key="event.id"
                                :class="['event-item', `priority-${event.priority || 'default'}`]"
                            >
                                <text class="event-title">{{ event.title }}</text>
                            </view>
                        </view>
                    </view>
                </view>
            </view>

            <!-- 日视图 -->
            <view v-else class="day-view">
                <view class="day-header">
                    <text class="day-title">{{ getDayTitle() }}</text>
                    <text class="day-subtitle">{{ getDaySubtitle() }}</text>
                </view>
                <view class="day-events">
                    <view 
                        v-for="event in selectedDayEvents" 
                        :key="event.id"
                        :class="['event-card', `priority-${event.priority || 'default'}`]"
                        @click="showEventDetail(event)"
                    >
                        <view class="event-header">
                            <text class="event-title">{{ event.title }}</text>
                            <text :class="['event-state', `state-${event.state}`]">
                                {{ getStateLabel(event.state) }}
                            </text>
                        </view>
                        <text v-if="event.description" class="event-description">
                            {{ event.description }}
                        </text>
                        <view class="event-meta">
                            <text class="event-time">
                                {{ event.allDay ? '全天' : getTimeDisplay(event) }}
                            </text>
                            <text class="event-priority">
                                {{ getPriorityLabel(event.priority) }}
                            </text>
                        </view>
                    </view>
                </view>
                <view v-if="selectedDayEvents.length === 0" class="empty-day">
                    <text class="empty-text">今天暂无任务</text>
                </view>
            </view>
        </scroll-view>
    </view>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted } from 'vue'
import { getMonthViewDates, getWeekViewDates, isToday as checkIsToday, getWeekdayName as getWeekdayShort } from './calendar-utils'

// 类型定义
interface CalendarEvent {
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

interface CalendarDate {
    date: Date
    day: number
    isToday: boolean
    isCurrentMonth: boolean
    events: CalendarEvent[]
}

type ViewType = 'day' | 'week' | 'month'

// 响应式数据
const currentDate = ref(new Date())
const selectedDate = ref(new Date())
const currentView = ref<ViewType>('month')

// 视图选项
const viewTypes = [
    { value: 'day' as ViewType, label: '日' },
    { value: 'week' as ViewType, label: '周' },
    { value: 'month' as ViewType, label: '月' }
]

const weekdays = ['日', '一', '二', '三', '四', '五', '六']

// 模拟事件数据
const events = ref<CalendarEvent[]>([
    {
        id: 1,
        title: '项目会议',
        startDate: '2025-01-11',
        startTime: '09:00',
        endTime: '10:30',
        priority: 'high',
        state: 'todo',
        description: '讨论项目进度和下一步计划'
    },
    {
        id: 2,
        title: '代码审查',
        startDate: '2025-01-11',
        startTime: '14:00',
        endTime: '15:00',
        priority: 'medium',
        state: 'in-progress'
    },
    {
        id: 3,
        title: '团队建设活动',
        startDate: '2025-01-12',
        allDay: true,
        priority: 'low',
        state: 'todo',
        description: '团队户外活动'
    }
])

// 计算属性
const currentTitle = computed(() => {
    const year = currentDate.value.getFullYear()
    const month = currentDate.value.getMonth() + 1
    const day = currentDate.value.getDate()
    
    switch (currentView.value) {
        case 'day':
            return `${year}年${month}月${day}日`
        case 'week':
            return `${year}年${month}月 第${getWeekOfMonth()}周`
        case 'month':
            return `${year}年${month}月`
        default:
            return `${year}年${month}月`
    }
})

const monthDates = computed(() => {
    const year = currentDate.value.getFullYear()
    const month = currentDate.value.getMonth() + 1
    return getMonthViewDates(year, month, events.value)
})

const weekDays = computed(() => {
    return getWeekViewDates(currentDate.value, events.value)
})

const selectedDayEvents = computed(() => {
    const dateString = selectedDate.value.toISOString().split('T')[0]
    return events.value.filter(event => {
        if (event.endDate) {
            return dateString >= event.startDate && dateString <= event.endDate
        }
        return event.startDate === dateString
    })
})

// 方法
function switchView(viewType: ViewType) {
    currentView.value = viewType
}

function goToPrev() {
    const newDate = new Date(currentDate.value)
    switch (currentView.value) {
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
    currentDate.value = newDate
}

function goToNext() {
    const newDate = new Date(currentDate.value)
    switch (currentView.value) {
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
    currentDate.value = newDate
}

function goToToday() {
    const today = new Date()
    currentDate.value = today
    selectedDate.value = today
}

function selectDate(date: Date) {
    selectedDate.value = date
    currentDate.value = date
    if (currentView.value === 'month') {
        currentView.value = 'day'
    }
}

function isSelectedDate(date: Date): boolean {
    return date.toDateString() === selectedDate.value.toDateString()
}

function getWeekOfMonth(): number {
    const firstDay = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth(), 1)
    const dayOfMonth = currentDate.value.getDate()
    return Math.ceil((dayOfMonth + firstDay.getDay()) / 7)
}

function getWeekdayName(dayIndex: number): string {
    return getWeekdayShort(dayIndex, true)
}

function getDayTitle(): string {
    const weekday = getWeekdayName(selectedDate.value.getDay())
    const day = selectedDate.value.getDate()
    return `${weekday} ${day}日`
}

function getDaySubtitle(): string {
    const year = selectedDate.value.getFullYear()
    const month = selectedDate.value.getMonth() + 1
    return `${year}年${month}月`
}

function getPriorityLabel(priority?: string): string {
    switch (priority) {
        case 'urgent': return '紧急'
        case 'high': return '高'
        case 'medium': return '中'
        case 'low': return '低'
        default: return ''
    }
}

function getStateLabel(state?: string): string {
    switch (state) {
        case 'todo': return '待办'
        case 'in-progress': return '进行中'
        case 'done': return '已完成'
        default: return '待办'
    }
}

function getTimeDisplay(event: CalendarEvent): string {
    if (!event.startTime) return ''
    if (event.endTime) {
        return `${event.startTime}-${event.endTime}`
    }
    return event.startTime
}

function showEventDetail(event: CalendarEvent) {
    // TODO: 显示事件详情
    console.log('显示事件详情:', event)
}

// 初始化
onMounted(() => {
    goToToday()
})
</script>

<style scoped>
@import url('./index.css');
</style>
