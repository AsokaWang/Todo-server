<template>
    <div class="calendar-header">
        <!-- 左侧：视图切换和标题 -->
        <div class="calendar-header-left">
            <!-- 视图切换按钮 -->
            <div class="view-switcher">
                <button
                    v-for="view in viewTypes"
                    :key="view.value"
                    :class="['view-btn', { active: viewType === view.value }]"
                    @click="handleViewChange(view.value)"
                >
                    {{ view.label }}
                </button>
            </div>
            
            <!-- 标题 -->
            <h1 class="calendar-title">{{ title }}</h1>
        </div>

        <!-- 中间：导航控制 -->
        <div class="calendar-navigation">
            <button class="nav-btn" @click="$emit('prev')" title="上一个">
                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <polyline points="15,18 9,12 15,6"></polyline>
                </svg>
            </button>
            
            <button class="nav-btn today-btn" @click="$emit('today')">
                今天
            </button>
            
            <button class="nav-btn" @click="$emit('next')" title="下一个">
                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <polyline points="9,6 15,12 9,18"></polyline>
                </svg>
            </button>
        </div>

        <!-- 右侧：操作按钮 -->
        <div class="calendar-header-right">
            <button class="action-btn" @click="$emit('refresh')" :disabled="loading">
                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" :class="{ spinning: loading }">
                    <polyline points="23,4 23,10 17,10"></polyline>
                    <polyline points="1,20 1,14 7,14"></polyline>
                    <path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4L18.36 18.36A9 9 0 0 1 3.51 15"></path>
                </svg>
                刷新
            </button>
            
            <button class="action-btn primary" @click="$emit('add-event')">
                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                添加任务
            </button>
        </div>
    </div>
</template>

<script lang="ts" setup>
import type { CalendarViewType } from '../types'

interface Props {
    viewType: CalendarViewType
    title: string
    loading?: boolean
}

interface Emits {
    (e: 'view-change', viewType: CalendarViewType): void
    (e: 'prev'): void
    (e: 'next'): void
    (e: 'today'): void
    (e: 'refresh'): void
    (e: 'add-event'): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()

const viewTypes = [
    { value: 'day' as CalendarViewType, label: '日' },
    { value: 'week' as CalendarViewType, label: '周' },
    { value: 'month' as CalendarViewType, label: '月' }
]

function handleViewChange(newViewType: CalendarViewType) {
    emit('view-change', newViewType)
}
</script>

<style scoped>
.calendar-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px 20px;
    background: #ffffff;
    border-bottom: 1px solid #e5e7eb;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.calendar-header-left {
    display: flex;
    align-items: center;
    gap: 20px;
}

.view-switcher {
    display: flex;
    background: #f3f4f6;
    border-radius: 8px;
    padding: 2px;
}

.view-btn {
    padding: 8px 16px;
    border: none;
    background: transparent;
    color: #6b7280;
    font-size: 14px;
    font-weight: 500;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
}

.view-btn:hover {
    background: #e5e7eb;
    color: #374151;
}

.view-btn.active {
    background: #ffffff;
    color: #1f2937;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.calendar-title {
    font-size: 24px;
    font-weight: 600;
    color: #1f2937;
    margin: 0;
}

.calendar-navigation {
    display: flex;
    align-items: center;
    gap: 8px;
}

.nav-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 8px;
    border: 1px solid #d1d5db;
    background: #ffffff;
    color: #6b7280;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
}

.nav-btn:hover {
    background: #f9fafb;
    border-color: #9ca3af;
    color: #374151;
}

.nav-btn .icon {
    width: 16px;
    height: 16px;
    stroke-width: 2;
}

.today-btn {
    padding: 8px 16px;
    font-size: 14px;
    font-weight: 500;
}

.calendar-header-right {
    display: flex;
    align-items: center;
    gap: 12px;
}

.action-btn {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 8px 16px;
    border: 1px solid #d1d5db;
    background: #ffffff;
    color: #374151;
    font-size: 14px;
    font-weight: 500;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
}

.action-btn:hover {
    background: #f9fafb;
    border-color: #9ca3af;
}

.action-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.action-btn.primary {
    background: #3b82f6;
    border-color: #3b82f6;
    color: #ffffff;
}

.action-btn.primary:hover {
    background: #2563eb;
    border-color: #2563eb;
}

.action-btn .icon {
    width: 16px;
    height: 16px;
    stroke-width: 2;
}

.spinning {
    animation: spin 1s linear infinite;
}

@keyframes spin {
    from {
        transform: rotate(0deg);
    }
    to {
        transform: rotate(360deg);
    }
}

/* 响应式设计 */
@media (max-width: 768px) {
    .calendar-header {
        flex-direction: column;
        gap: 12px;
        padding: 12px 16px;
    }
    
    .calendar-header-left,
    .calendar-header-right {
        width: 100%;
        justify-content: center;
    }
    
    .calendar-title {
        font-size: 20px;
    }
}
</style>