<template>
  <div class="base-flex-wrap" align-v="center">

    <base-input-chosen-one ref="nameComponentRef"
      :namespace="`${namespace}.name`"
      :options="nameOptions"
    />

    <component :is="valueComponent" ref="valueComponentRef"
      :namespace="`${namespace}.value`"
    />

  </div>
</template>
<script>
import {
  BaseInput,
  BaseInputNumber,
  BaseInputChosenOne,
} from '@/components/new'

const components = {
  BaseInput,
  BaseInputNumber,
  BaseInputChosenOne
}

import { configFields } from '../config'
import { computed, nextTick, ref, unref, watch } from '@vue/composition-api'
import {
  pfComponentType as componentType,
  pfFieldTypeComponent as fieldTypeComponent
} from '@/globals/pfField'
import { useInputMeta, useInputMetaProps } from '@/composables/useMeta'
import { useInputValue, useInputValueProps } from '@/composables/useInputValue'

const props = {
  ...useInputMetaProps,
  ...useInputValueProps
}

const setup = (props, context) => {

  const metaProps = useInputMeta(props, context)

  const {
    value: inputValue,
    onChange
  } = useInputValue(metaProps, context)

  const nameComponentRef = ref(null)
  const nameOptions = Object.values(configFields).sort((a, b) => a.value.localeCompare(b.value))

  watch( // when `name` is mutated
    () => unref(inputValue) && unref(inputValue).name,
    () => {
      const { isFocus = false } = nameComponentRef.value
      if (isFocus) { // and `name` isFocus
        onChange({ ...unref(inputValue), value: undefined }) // clear `value`

        nextTick(() => {
          const { doFocus = () => {} } = valueComponentRef.value || {}
          doFocus() // focus `value` component
        })
      }
    }
  )

  const valueComponentRef = ref(null)
  const valueComponent = computed(() => {
    const { name } = unref(inputValue) || {}
    const { [name]: { types = [] } = {} } = configFields
    for (let t = 0; t < types.length; t++) {
      let type = types[t]
      let component = fieldTypeComponent[type]
      switch (component) {
        case componentType.SUBSTRING:
          return BaseInput
          // break

        case componentType.INTEGER:
          return BaseInputNumber
          // break

        case componentType.HIDDEN:
        case componentType.NONE:
          return undefined
          // break

        default:
          // eslint-disable-next-line
          console.error(`Unhandled pfComponentType '${component}' for pfFieldType '${name}'`)
      }
    }
    return undefined
  })

  return {
    nameComponentRef,
    nameOptions,
    valueComponent,
    valueComponentRef
  }
}

// @vue/component
export default {
  name: 'base-host-config-config',
  inheritAttrs: false,
  components,
  props,
  setup
}
</script>

