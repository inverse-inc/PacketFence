<template>
  <div class="w-100 py-2">
    <b-link @click="doToggle"
      class="d-block"
      :class="{
        'text-danger': inputState === false,
        'text-primary': inputState !== false && actionKey,
        'text-secondary': inputState !== false && !actionKey
      }"
    >
      <icon v-if="!isCollapse" name="chevron-circle-down" class="mr-2 mb-1"/>
      <icon v-else name="chevron-circle-right" class="mr-2 mb-1"/>
      {{ ruleName }}
    </b-link>
    <b-collapse :visible="!isCollapse" tabIndex="-1" ref="rootRef" @show="onShow" @hidden="onHidden">
      <template v-if="isRendered">
        <form-group-host :namespace="`${namespace}.host`"
          :column-label="$i18n.t('Host')"
          :label-cols="2"
        />
        <form-group-config :namespace="`${namespace}.config`"
          :column-label="$i18n.t('Configuration')"
          :label-cols="2"
        />
      </template>
    </b-collapse>
  </div>
</template>
<script>
import {computed, inject, unref} from '@vue/composition-api'
import {
  BaseFormGroupInput,
} from '@/components/new/'
import BaseFormGroupHostConfig from './BaseFormGroupHostConfig'

const components = {
  FormGroupHost: BaseFormGroupInput,
  FormGroupConfig: BaseFormGroupHostConfig,
}

import useArrayCollapse from '@/composables/useArrayCollapse'
import useEventActionKey from '@/composables/useEventActionKey'
import { useInputProps } from '@/composables/useInput'
import { useInputMeta, useInputMetaProps } from '@/composables/useMeta'
import { useInputValidator, useInputValidatorProps } from '@/composables/useInputValidator'
import { useInputValue, useInputValueProps } from '@/composables/useInputValue'
import ProvidedKeys from '@/views/Configuration/sources/_components/ldapCondition/ProvidedKeys';

const props = {
  ...useInputProps,
  ...useInputMetaProps,
  ...useInputValidatorProps,
  ...useInputValueProps,

  value: {
    type: Object
  }
}

const setup = (props, context) => {
  const conditionsComponent = inject(ProvidedKeys.conditionsComponent, components.FormGroupConditions)

  const metaProps = useInputMeta(props, context)

  const {
    value
  } = useInputValue(metaProps, context)

  const {
    state
  } = useInputValidator(metaProps, value)

  const ruleName = computed(() => {
    const { host } = unref(value) || {}
    return host || 'unknown'
  })

  const actionKey = useEventActionKey()

  const {
    isCollapse,
    isRendered,

    doToggle,
    doCollapse,
    doExpand,
    onShow,
    onHidden
  } = useArrayCollapse(actionKey, context)

  return {
    inputState: state,
    inputValue: value,

    ruleName,
    actionKey,
    isCollapse,
    isRendered,

    doToggle,
    doCollapse,
    doExpand,
    onShow,
    onHidden,
    conditionsComponent
  }
}

// @vue/component
export default {
  name: 'base-host-config',
  inheritAttrs: false,
  components,
  props,
  setup
}
</script>
