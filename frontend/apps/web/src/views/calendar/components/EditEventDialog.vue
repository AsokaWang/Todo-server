<template>
    <div class="dialog-overlay" @click.self="$emit('close')">
        <div class="dialog-content">
            <!-- 对话框头部 -->
            <div class="dialog-header">
                <h2 class="dialog-title">编辑任务</h2>
                <button class="close-btn" @click="$emit('close')">
                    <svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>

            <!-- 对话框内容 -->
            <div class="dialog-body">
                <form @submit.prevent="handleSubmit">
                    <!-- 任务标题 -->
                    <div class="form-group">
                        <label class="form-label">任务标题 *</label>
                        <input
                            v-model="form.title"
                            type="text"
                            class="form-input"
                            placeholder="请输入任务标题"
                            required
                        />
                    </div>

                    <!-- 任务描述 -->
                    <div class="form-group">
                        <label class="form-label">任务描述</label>
                        <textarea
                            v-model="form.description"
                            class="form-textarea"
                            placeholder="请输入任务描述（可选）"
                            rows="3"
                        ></textarea>
                    </div>

                    <!-- 时间设置 -->
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">开始日期 *</label>
                            <input
                                v-model="form.startDate"
                                type="date"
                                class="form-input"
                                required
                            />
                        </div>
                        <div class="form-group">
                            <label class="form-label">结束日期</label>
                            <input
                                v-model="form.endDate"
                                type="date"
                                class="form-input"
                                :min="form.startDate"
                            />
                        </div>
                    </div>

                    <!-- 全天事件切换 -->
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input
                                v-model="form.allDay"
                                type="checkbox"
                                class="checkbox-input"
                            />
                            <span class="checkbox-text">全天事件</span>
                        </label>
                    </div>

                    <!-- 时间设置（非全天） -->
                    <div v-if="!form.allDay" class="form-row">
                        <div class="form-group">
                            <label class="form-label">开始时间</label>
                            <input
                                v-model="form.startTime"
                                type="time"
                                class="form-input"
                            />
                        </div>
                        <div class="form-group">
                            <label class="form-label">结束时间</label>
                            <input
                                v-model="form.endTime"
                                type="time"
                                class="form-input"
                                :min="form.startTime"
                            />
                        </div>
                    </div>

                    <!-- 优先级 -->
                    <div class="form-group">
                        <label class="form-label">优先级</label>
                        <div class="priority-options">
                            <label
                                v-for="priority in priorityOptions"
                                :key="priority.value"
                                :class="['priority-option', { active: form.priority === priority.value }]"
                                :style="{ borderColor: priority.color, backgroundColor: form.priority === priority.value ? priority.color + '20' : 'transparent' }"
                            >
                                <input
                                    v-model="form.priority"
                                    type="radio"
                                    :value="priority.value"
                                    class="priority-radio"
                                />
                                <span class="priority-dot" :style="{ backgroundColor: priority.color }"></span>
                                <span class="priority-text">{{ priority.label }}</span>
                            </label>
                        </div>
                    </div>

                    <!-- 状态 -->
                    <div class="form-group">
                        <label class="form-label">状态</label>
                        <select v-model="form.state" class="form-select">
                            <option value="todo">待办</option>
                            <option value="in-progress">进行中</option>
                            <option value="done">已完成</option>
                        </select>
                    </div>
                </form>
            </div>

            <!-- 对话框底部 -->
            <div class="dialog-footer">
                <button class="btn btn-secondary" @click="$emit('close')">
                    取消
                </button>
                <button class="btn btn-primary" @click="handleSubmit">
                    保存修改
                </button>
            </div>
        </div>
    </div>
</template>

<script lang="ts" setup>
import { reactive, watch, onMounted } from 'vue'
import type { CalendarEvent } from '../types'

interface Props {
    event: CalendarEvent
}

interface Emits {
    (e: 'close'): void
    (e: 'save', data: any): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const priorityOptions = [
    { value: 'low', label: '低', color: '#22c55e' },
    { value: 'medium', label: '中', color: '#eab308' },
    { value: 'high', label: '高', color: '#f97316' },
    { value: 'urgent', label: '紧急', color: '#ef4444' }
]

const form = reactive({
    title: '',
    description: '',
    startDate: '',
    endDate: '',
    startTime: '',
    endTime: '',
    allDay: true,
    priority: 'medium',
    state: 'todo'
})

// 初始化表单数据
function initializeForm() {
    if (props.event) {
        form.title = props.event.title || ''
        form.description = props.event.description || ''
        form.startDate = props.event.startDate || ''
        form.endDate = props.event.endDate || ''
        form.startTime = props.event.startTime || ''
        form.endTime = props.event.endTime || ''
        form.allDay = props.event.allDay !== false
        form.priority = props.event.priority || 'medium'
        form.state = props.event.state || 'todo'
    }
}

// 监听全天事件变化
watch(() => form.allDay, (isAllDay) => {
    if (isAllDay) {
        form.startTime = ''
        form.endTime = ''
    } else if (!form.startTime) {
        // 如果切换到非全天，设置默认时间
        const now = new Date()
        const hour = now.getHours()
        form.startTime = `${hour.toString().padStart(2, '0')}:00`
        form.endTime = `${((hour + 1) % 24).toString().padStart(2, '0')}:00`
    }
})

// 处理表单提交
function handleSubmit() {
    if (!form.title.trim()) {
        return
    }

    const eventData = {
        id: props.event.id,
        title: form.title.trim(),
        description: form.description.trim() || undefined,
        startDate: form.startDate,
        endDate: form.endDate || undefined,
        startTime: form.allDay ? undefined : form.startTime,
        endTime: form.allDay ? undefined : form.endTime,
        allDay: form.allDay,
        priority: form.priority,
        state: form.state,
        color: priorityOptions.find(p => p.value === form.priority)?.color || '#6b7280'
    }

    emit('save', eventData)
}

// 组件挂载时初始化表单
onMounted(() => {
    initializeForm()
})
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
    max-width: 600px;
    width: 90%;
    max-height: 90vh;
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

.form-group {
    margin-bottom: 20px;
}

.form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    margin-bottom: 20px;
}

.form-label {
    display: block;
    font-size: 14px;
    font-weight: 500;
    color: #374151;
    margin-bottom: 6px;
}

.form-input,
.form-textarea,
.form-select {
    width: 100%;
    padding: 10px 12px;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    font-size: 14px;
    color: #374151;
    background: #ffffff;
    transition: all 0.2s;
}

.form-input:focus,
.form-textarea:focus,
.form-select:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-textarea {
    resize: vertical;
    min-height: 80px;
}

.checkbox-label {
    display: flex;
    align-items: center;
    gap: 8px;
    cursor: pointer;
}

.checkbox-input {
    width: 16px;
    height: 16px;
    accent-color: #3b82f6;
}

.checkbox-text {
    font-size: 14px;
    color: #374151;
}

.priority-options {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
}

.priority-option {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
}

.priority-option:hover {
    border-color: #d1d5db;
    background: #f9fafb;
}

.priority-option.active {
    border-color: currentColor;
}

.priority-radio {
    position: absolute;
    opacity: 0;
    pointer-events: none;
}

.priority-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
}

.priority-text {
    font-size: 14px;
    color: #374151;
    font-weight: 500;
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
    padding: 10px 20px;
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

/* 响应式设计 */
@media (max-width: 768px) {
    .dialog-content {
        max-width: 95%;
        margin: 20px;
        max-height: 95vh;
    }
    
    .form-row {
        grid-template-columns: 1fr;
        gap: 12px;
    }
    
    .priority-options {
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