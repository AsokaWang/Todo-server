<template>
    <nue-div align="stretch" class="todo-creator-wrapper" vertical>
        <nue-input v-model="todoData.name" clearable placeholder="待办事项名称" />
        <nue-div v-if="setMoreData" align="stretch" vertical>
            <nue-div wrap="nowrap" gap="8px">
                <todo-selector
                    :options="TodoStateSelectOptions"
                    :value="todoData.state"
                    @change="(s) => (todoData.state = s as CreateTodoOptions['state'])"
                />
                <todo-selector
                    :options="TodoPrioritySelectOptions"
                    :value="todoData.priority"
                    @change="(p) => (todoData.priority = p as CreateTodoOptions['priority'])"
                />
                <nue-div flex />
                <todo-project-selector
                    :project-id="todoData.projectId"
                    :projects="projects"
                    :user-id="userId"
                    @select="setProjectInfo"
                />
            </nue-div>
            <nue-div align="stretch" vertical gap="8px">
                <nue-text size="14px" weight="500" color="gray">时间设置</nue-text>
                <nue-div align="stretch" vertical gap="8px">
                    <nue-div align="center" gap="8px" wrap="nowrap">
                        <nue-text size="12px" color="gray" style="min-width: 40px;">开始:</nue-text>
                        <todo-date-selector 
                            v-model="todoData.dueDate.startAt" 
                            button-text="设置开始时间"
                        />
                    </nue-div>
                    <nue-div v-if="todoData.dueDate.startAt" align="center" gap="8px">
                        <nue-div style="min-width: 40px;"></nue-div>
                        <nue-text color="gray" size="12px">
                            {{ useRelativeDate(todoData.dueDate.startAt) }}
                        </nue-text>
                    </nue-div>
                </nue-div>
                <nue-div align="stretch" vertical gap="8px">
                    <nue-div align="center" gap="8px" wrap="nowrap">
                        <nue-text size="12px" color="gray" style="min-width: 40px;">结束:</nue-text>
                        <todo-date-selector 
                            v-model="todoData.dueDate.endAt" 
                            button-text="设置结束时间"
                        />
                    </nue-div>
                    <nue-div v-if="todoData.dueDate.endAt" align="center" gap="8px">
                        <nue-div style="min-width: 40px;"></nue-div>
                        <nue-text color="gray" size="12px">
                            {{ useRelativeDate(todoData.dueDate.endAt) }}
                        </nue-text>
                    </nue-div>
                </nue-div>
            </nue-div>
            <todo-tag-bar
                :clamped="5"
                :tags="tags"
                :todo-tags="todoData.tags!"
                @update-tags="handleUpdateTags"
            />
            <nue-textarea
                v-model="todoData.description"
                :rows="4"
                placeholder="添加待办事项备注（可选）"
            />
        </nue-div>
    </nue-div>
</template>

<script lang="ts" setup>
import { reactive, ref } from 'vue'
import { TodoDateSelector, TodoProjectSelector, TodoTagBar } from '@nao-todo/components'
import { TodoPrioritySelectOptions, TodoSelector, TodoStateSelectOptions } from '../selector'
import { useRelativeDate } from '@nao-todo/hooks/use-relative-date'
import type { CreateTodoOptions } from '@nao-todo/types'
import type { TodoCreatorProps } from './types'

defineOptions({ name: 'TodoCreatorUI' })
const props = defineProps<TodoCreatorProps>()

const setMoreData = ref(true)
const todoData = reactive<CreateTodoOptions>({
    name: '',
    dueDate: { 
        startAt: null, 
        endAt: null,
        startTime: null,
        endTime: null,
        allDay: true
    },
    priority: 'low',
    state: 'todo',
    projectId: '',
    description: '',
    tags: [],
    ...props.presetInfo
})

const setProjectInfo = (projectId: string) => {
    todoData.projectId = projectId
}

const handleUpdateTags = (tags: string[]) => {
    todoData.tags = tags
}

const handleClearData = () => {
    todoData.name = ''
    todoData.dueDate = { 
        startAt: null, 
        endAt: null,
        startTime: null,
        endTime: null,
        allDay: true
    }
    todoData.priority = 'low'
    todoData.state = 'todo'
    todoData.projectId = ''
    todoData.description = ''
    todoData.tags = []
}

defineExpose({
    todoData,
    clear: handleClearData
})
</script>
