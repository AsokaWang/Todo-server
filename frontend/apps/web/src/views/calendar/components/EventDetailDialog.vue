<template>
    <div class="dialog-overlay" @click.self="$emit('close')">
        <div class="dialog-content">
            <!-- 对话框头部 -->
            <div class="dialog-header">
                <h2 class="dialog-title">任务详情</h2>
                <button class="close-btn" @click="$emit('close')">
                    <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>

            <!-- 对话框内容 -->
            <div class="dialog-body">
                <div class="event-header">
                    <div class="event-icon" :style="{ backgroundColor: event?.color || '#6b7280' }">
                        <span v-if="event?.state === 'done'">✓</span>
                        <span v-else>📋</span>
                    </div>
                    <div class="event-info">
                        <h3 class="event-title">{{ event?.title || '未命名任务' }}</h3>
                        <div class="event-meta">
                            <span class="priority-badge" :class="`priority-${event?.priority || 'default'}`">
                                {{ getPriorityLabel(event?.priority) }}
                            </span>
                            <span class="state-badge" :class="`state-${event?.state || 'todo'}`">
                                {{ getStateLabel(event?.state) }}
                            </span>
                        </div>
                    </div>
                </div>

                <div class="event-details">
                    <!-- 时间信息 -->
                    <div class="detail-section">
                        <div class="detail-label">时间</div>
                        <div class="detail-value">
                            <div class="time-info">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                    <line x1="16" y1="2" x2="16" y2="6"></line>
                                    <line x1="8" y1="2" x2="8" y2="6"></line>
                                    <line x1="3" y1="10" x2="21" y2="10"></line>
                                </svg>
                                <span>{{ getDateDisplay() }}</span>
                            </div>
                            <div v-if="!event?.allDay && event?.startTime" class="time-info">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                                    <circle cx="12" cy="12" r="10"></circle>
                                    <polyline points="12,6 12,12 16,14"></polyline>
                                </svg>
                                <span>{{ getTimeDisplay() }}</span>
                            </div>
                        </div>
                    </div>

                    <!-- 描述信息 -->
                    <div v-if="event?.description" class="detail-section">
                        <div class="detail-label">描述</div>
                        <div class="detail-value">
                            <p class="description-text">{{ event.description }}</p>
                        </div>
                    </div>

                    <!-- 任务统计 -->
                    <div class="detail-section">
                        <div class="detail-label">任务信息</div>
                        <div class="detail-value">
                            <div class="info-grid">
                                <div class="info-item">
                                    <span class="info-label">任务ID</span>
                                    <span class="info-value">{{ event?.id }}</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">创建时间</span>
                                    <span class="info-value">{{ formatDate(event?.startDate) }}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 对话框底部 -->
            <div class="dialog-footer">
                <button class="btn btn-secondary" @click="$emit('close')">
                    关闭
                </button>
                <button class="btn btn-primary" @click="$emit('edit', event)">
                    编辑
                </button>
                <button class="btn btn-danger" @click="handleDelete">
                    删除
                </button>
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import type { CalendarEvent } from '../types'

interface Props {
    event: CalendarEvent | null
}

interface Emits {
    (e: 'close'): void
    (e: 'edit', event: CalendarEvent): void
    (e: 'delete', event: CalendarEvent): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

function getPriorityLabel(priority?: string): string {
    switch (priority) {
        case 'urgent': return '紧急'
        case 'high': return '高优先级'
        case 'medium': return '中优先级'
        case 'low': return '低优先级'
        default: return '普通'
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

function getDateDisplay(): string {
    if (!props.event) return ''
    
    if (props.event.endDate && props.event.endDate !== props.event.startDate) {
        return `${formatDate(props.event.startDate)} - ${formatDate(props.event.endDate)}`
    }
    return formatDate(props.event.startDate)
}

function getTimeDisplay(): string {
    if (!props.event || props.event.allDay) return '全天'
    
    if (props.event.endTime) {
        return `${props.event.startTime} - ${props.event.endTime}`
    }
    return props.event.startTime || ''
}

function formatDate(dateString?: string): string {
    if (!dateString) return ''
    
    const date = new Date(dateString)
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    
    return `${year}年${month}月${day}日`
}

function handleDelete() {
    if (props.event) {
        emit('delete', props.event)
    }
}
</script>

<style scoped>
.dialog-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
}

.dialog-content {
    background: #ffffff;
    border-radius: 12px;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    max-width: 500px;
    width: 90%;
    max-height: 80vh;
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

.dialog-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 20px 24px;
    border-bottom: 1px solid #e5e7eb;
}

.dialog-title {
    font-size: 18px;
    font-weight: 600;
    color: #111827;
    margin: 0;
}

.close-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    border: none;
    background: #f3f4f6;
    color: #6b7280;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
}

.close-btn:hover {
    background: #e5e7eb;
    color: #374151;
}

.dialog-body {
    flex: 1;
    overflow-y: auto;
    padding: 24px;
}

.event-header {
    display: flex;
    align-items: flex-start;
    gap: 16px;
    margin-bottom: 24px;
}

.event-icon {
    width: 48px;
    height: 48px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    color: #ffffff;
    flex-shrink: 0;
}

.event-info {
    flex: 1;
}

.event-title {
    font-size: 20px;
    font-weight: 600;
    color: #111827;
    margin: 0 0 8px 0;
}

.event-meta {
    display: flex;
    gap: 8px;
}

.priority-badge,
.state-badge {
    padding: 4px 8px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 500;
}

.priority-urgent { background: #fee2e2; color: #dc2626; }
.priority-high { background: #fed7aa; color: #ea580c; }
.priority-medium { background: #fef3c7; color: #d97706; }
.priority-low { background: #d1fae5; color: #059669; }
.priority-default { background: #f3f4f6; color: #6b7280; }

.state-todo { background: #f3f4f6; color: #6b7280; }
.state-in-progress { background: #dbeafe; color: #2563eb; }
.state-done { background: #d1fae5; color: #059669; }

.event-details {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.detail-section {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.detail-label {
    font-size: 14px;
    font-weight: 600;
    color: #374151;
}

.detail-value {
    color: #6b7280;
}

.time-info {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 4px;
}

.time-info:last-child {
    margin-bottom: 0;
}

.icon {
    width: 16px;
    height: 16px;
    stroke-width: 1.5;
}

.description-text {
    margin: 0;
    line-height: 1.6;
    white-space: pre-wrap;
}

.info-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
}

.info-item {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.info-label {
    font-size: 12px;
    font-weight: 500;
    color: #9ca3af;
    text-transform: uppercase;
}

.info-value {
    font-size: 14px;
    color: #374151;
}

.dialog-footer {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 12px;
    padding: 20px 24px;
    border-top: 1px solid #e5e7eb;
}

.btn {
    padding: 8px 16px;
    border: 1px solid;
    border-radius: 6px;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
}

.btn-secondary {
    background: #ffffff;
    border-color: #d1d5db;
    color: #374151;
}

.btn-secondary:hover {
    background: #f9fafb;
    border-color: #9ca3af;
}

.btn-primary {
    background: #3b82f6;
    border-color: #3b82f6;
    color: #ffffff;
}

.btn-primary:hover {
    background: #2563eb;
    border-color: #2563eb;
}

.btn-danger {
    background: #ef4444;
    border-color: #ef4444;
    color: #ffffff;
}

.btn-danger:hover {
    background: #dc2626;
    border-color: #dc2626;
}

/* 响应式设计 */
@media (max-width: 768px) {
    .dialog-content {
        max-width: 95%;
        margin: 20px;
    }
    
    .info-grid {
        grid-template-columns: 1fr;
    }
    
    .dialog-footer {
        flex-direction: column-reverse;
        gap: 8px;
    }
    
    .btn {
        width: 100%;
        justify-content: center;
    }
}
</style>