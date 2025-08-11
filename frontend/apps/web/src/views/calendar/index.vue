<template>
    <div class="calendar-container">
        <!-- 日历头部 -->
        <CalendarHeader
            :view-type="calendarStore.viewType"
            :title="calendarStore.navigation.title"
            :loading="calendarStore.isLoading"
            @view-change="handleViewChange"
            @prev="calendarStore.goToPrev"
            @next="calendarStore.goToNext"
            @today="calendarStore.goToToday"
            @refresh="calendarStore.refresh"
            @add-event="handleAddEvent"
        />

        <!-- 日历内容区域 -->
        <div class="calendar-content">
            <!-- 月视图 -->
            <MonthView
                v-if="calendarStore.viewType === 'month'"
                :current-date="calendarStore.currentDate"
                :selected-date="calendarStore.selectedDate"
                :events="calendarStore.events"
                @date-click="handleDateClick"
                @event-click="handleEventClick"
                @show-more-events="handleShowMoreEvents"
                @add-event="handleAddEvent"
            />

            <!-- 周视图 -->
            <WeekView
                v-else-if="calendarStore.viewType === 'week'"
                :current-date="calendarStore.currentDate"
                :selected-date="calendarStore.selectedDate"
                :events="calendarStore.events"
                @day-click="handleDayClick"
                @hour-click="handleHourClick"
                @event-click="handleEventClick"
            />

            <!-- 日视图 -->
            <DayView
                v-else-if="calendarStore.viewType === 'day'"
                :current-date="calendarStore.currentDate"
                :events="calendarStore.selectedDateEvents"
                @hour-click="handleHourClick"
                @event-click="handleEventClick"
            />
        </div>

        <!-- 事件详情弹窗 -->
        <EventDetailDialog
            v-if="showEventDetail"
            :event="selectedEvent"
            @close="handleCloseEventDetail"
            @edit="handleEditEvent"
            @delete="handleDeleteEvent"
        />

        <!-- 添加事件弹窗 -->
        <AddEventDialog
            v-if="showAddEvent"
            :default-date="defaultEventDate"
            :default-time="defaultEventTime"
            @close="handleCloseAddEvent"
            @save="handleSaveEvent"
        />

        <!-- 编辑事件弹窗 -->
        <EditEventDialog
            v-if="showEditEvent && editEvent"
            :event="editEvent"
            @close="handleCloseEditEvent"
            @save="handleSaveEditEvent"
        />
    </div>
</template>

<script lang="ts" setup>
import { ref, onMounted } from 'vue'
import { NueMessage } from 'nue-ui'
import CalendarHeader from './components/CalendarHeader.vue'
import MonthView from './components/MonthView.vue'
import WeekView from './components/WeekView.vue'
import DayView from './components/DayView.vue'
import EventDetailDialog from './components/EventDetailDialog.vue'
import AddEventDialog from './components/AddEventDialog.vue'
import EditEventDialog from './components/EditEventDialog.vue'
import { useCalendarStore } from './composables/use-calendar-store'
import { useTodoStore } from '../../stores/use-todo-store'
import { useViewStore } from '../../stores/use-view-store'
import type { CalendarViewType, CalendarEvent, CalendarDate } from './types'

// 使用日历存储和待办存储
const calendarStore = useCalendarStore()
const todoStore = useTodoStore()
const viewStore = useViewStore()

// 弹窗状态
const showEventDetail = ref(false)
const showAddEvent = ref(false)
const showEditEvent = ref(false)
const selectedEvent = ref<CalendarEvent | null>(null)
const editEvent = ref<CalendarEvent | null>(null)
const defaultEventDate = ref<Date | null>(null)
const defaultEventTime = ref<number | null>(null)

// 处理视图类型变更
function handleViewChange(viewType: CalendarViewType) {
    calendarStore.setViewType(viewType)
}

// 处理日期点击（月视图）
function handleDateClick(date: Date) {
    calendarStore.setSelectedDate(date)
    if (calendarStore.viewType === 'month') {
        // 从月视图切换到日视图
        calendarStore.setCurrentDate(date)
        calendarStore.setViewType('day')
    }
}

// 处理天点击（周视图）
function handleDayClick(date: Date) {
    calendarStore.setSelectedDate(date)
    calendarStore.setCurrentDate(date)
    calendarStore.setViewType('day')
}

// 处理小时点击
function handleHourClick(date: Date, hour?: number) {
    handleAddEvent(date, hour)
}

// 处理事件点击
function handleEventClick(event: CalendarEvent) {
    selectedEvent.value = event
    showEventDetail.value = true
}

// 处理显示更多事件
function handleShowMoreEvents(date: CalendarDate) {
    calendarStore.setSelectedDate(date.date)
    calendarStore.setCurrentDate(date.date)
    calendarStore.setViewType('day')
}

// 处理添加事件
function handleAddEvent(date?: Date, hour?: number) {
    defaultEventDate.value = date || calendarStore.currentDate
    defaultEventTime.value = hour ?? null
    showAddEvent.value = true
    // 临时隐藏任务详情面板以避免UI冲突
    if (viewStore.tasksOutlineVisible) {
        viewStore.tasksOutlineVisible = false
    }
}

// 处理关闭事件详情
function handleCloseEventDetail() {
    showEventDetail.value = false
    selectedEvent.value = null
}

// 处理编辑事件
function handleEditEvent(event: CalendarEvent) {
    editEvent.value = event
    showEditEvent.value = true
    // 临时隐藏任务详情面板以避免UI冲突
    if (viewStore.tasksOutlineVisible) {
        viewStore.tasksOutlineVisible = false
    }
    handleCloseEventDetail()
}

// 处理删除事件
async function handleDeleteEvent(event: CalendarEvent) {
    try {
        // 软删除待办任务
        const success = await todoStore.deleteTodoWithConfirmation(event.id as string)
        
        if (success) {
            NueMessage.success('任务已删除')
            calendarStore.refresh()
        }
    } catch (error) {
        console.error('Failed to delete todo:', error)
        NueMessage.error('任务删除失败')
    }
    
    handleCloseEventDetail()
}

// 处理关闭添加事件
function handleCloseAddEvent() {
    showAddEvent.value = false
    defaultEventDate.value = null
    defaultEventTime.value = null
}

// 处理关闭编辑事件
function handleCloseEditEvent() {
    showEditEvent.value = false
    editEvent.value = null
}

// 处理保存事件
async function handleSaveEvent(eventData: any) {
    try {
        // 构建待办任务数据
        const todoOptions = {
            name: eventData.title,
            description: eventData.description || '',
            state: eventData.state || 'todo',
            priority: eventData.priority || 'medium',
            dueDate: {
                startAt: eventData.startDate,
                endAt: eventData.endDate || null,
                startTime: eventData.startTime || null,
                endTime: eventData.endTime || null,
                allDay: eventData.allDay !== false
            }
        }
        
        // 创建待办任务
        const newTodo = await todoStore.doCreateTodo(todoOptions, true)
        
        if (newTodo) {
            NueMessage.success('任务已创建')
        } else {
            NueMessage.error('任务创建失败')
        }
    } catch (error) {
        console.error('Failed to create todo:', error)
        NueMessage.error('任务创建失败')
    }
    
    handleCloseAddEvent()
    calendarStore.refresh()
}

// 处理编辑保存事件
async function handleSaveEditEvent(eventData: any) {
    try {
        // 构建更新数据
        const updateOptions = {
            name: eventData.title,
            description: eventData.description || '',
            state: eventData.state || 'todo',
            priority: eventData.priority || 'medium',
            dueDate: {
                startAt: eventData.startDate,
                endAt: eventData.endDate || null,
                startTime: eventData.startTime || null,
                endTime: eventData.endTime || null,
                allDay: eventData.allDay !== false
            }
        }
        
        // 更新待办任务
        const success = await todoStore.doUpdateTodo(eventData.id as string, updateOptions)
        
        if (success) {
            NueMessage.success('任务已更新')
        } else {
            NueMessage.error('任务更新失败')
        }
    } catch (error) {
        console.error('Failed to update todo:', error)
        NueMessage.error('任务更新失败')
    }
    
    handleCloseEditEvent()
    calendarStore.refresh()
}

// 初始化
onMounted(() => {
    calendarStore.initialize()
})
</script>

<style scoped>
.calendar-container {
    display: flex;
    flex-direction: column;
    height: 100vh;
    background: #f8fafc;
    position: relative;
    z-index: 1;
}

.calendar-content {
    flex: 1;
    padding: 16px 20px;
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

/* 确保确认框在最顶层 */
:deep(.nue-dialog-overlay) {
    z-index: 10000 !important;
}

:deep(.nue-dialog) {
    z-index: 10001 !important;
}

/* 响应式设计 */
@media (max-width: 768px) {
    .calendar-content {
        padding: 8px 12px;
    }
}
</style>
