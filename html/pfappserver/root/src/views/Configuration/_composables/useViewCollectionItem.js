import { computed, ref, toRefs, watch } from '@vue/composition-api'
import { useDebouncedWatchHandler } from '@/composables/useDebounce'
import { useQuerySelectorAll } from '@/composables/useDom'
import useEventActionKey from '@/composables/useEventActionKey'
import useEventEscapeKey from '@/composables/useEventEscapeKey'
import useEventJail from '@/composables/useEventJail'
import { useDefaultsFromMeta } from '@/composables/useMeta'
import { usePropsWrapper } from '@/composables/useProps'

import {
  BaseButtonHelp,
  BaseServices
} from '@/components/new/'
export const useViewCollectionItemComponents = {
  BaseButtonHelp,
  BaseServices,
}

export const useViewCollectionItemProps = {
  id: {
    type: String
  },
  isClone: {
    type: Boolean
  },
  isNew: {
    type: Boolean
  },
  labelActionKey: {
    type: String
  },
  labelCreate: {
    type: String
  },
  labelSave: {
    type: String
  },
}

export const useViewCollectionItem = (collection, props, context) => {

  const {
    useItemDefaults = useDefaultsFromMeta, // {}
    useItemConfirmSave = () => {},
    useItemTitle = () => {},
    useItemTitleBadge = () => {},
    useRouter: _useRouter = () => {},
    useStore: _useStore = () => {},
    useServices = () => {},
    useResponse = response => response, // store responses merged into form
    useTitleHelp = () => {},
  } = collection

  // merge props w/ params in useRouter method
  const useRouter = $router => usePropsWrapper(_useRouter($router), props)

  // merge props w/ params in useStore methods
  const useStore = $store => usePropsWrapper(_useStore($store), props)

  const {
    id,
    isClone,
    isNew
  } = toRefs(props)

  // template refs
  const rootRef = ref(null)
  useEventJail(rootRef)

  // state
  const form = ref({})
  const meta = ref({})
  const title = useItemTitle(props, context, form)
  const titleBadge = useItemTitleBadge(props, context, form)
  const titleHelp = useTitleHelp(props)
  const isModified = ref(false)
  const confirmSave = useItemConfirmSave(props, context, form)
  const services = useServices(props, context, form)

  // unhandled custom props
  const customProps = ref(context.attrs)

  const _invalidNodes = useQuerySelectorAll(rootRef, '.input-group.is-invalid')
  const isValid = useDebouncedWatchHandler(
    [form, meta, _invalidNodes],
    () => (
      !rootRef.value ||
      Array.prototype.slice.call(rootRef.value.querySelectorAll('.is-invalid'))
        .filter(el => el.closest('fieldset').style.display !== 'none') // handle v-show <.. style="display: none;">
        .length === 0
    )
  )

  const { root: { $router, $store } = {} } = context

  const {
    goToCollection,
    goToItem,
    goToClone,
  } = useRouter($router)

  const {
    isLoading,
    getListOptions = () => (new Promise(r => r())),
    createItem,
    getItem,
    getItemOptions = () => (new Promise(r => r())),
    deleteItem,
    updateItem,
  } = useStore($store)

  const isSaveable = computed(() => {
    if (isNew.value || isClone.value)
      return !!createItem
    return !!updateItem
  })

  const isCloneable = computed(() => !!goToClone)

  const isDeletable = computed(() => {
      if (isNew.value || isClone.value)
        return false
      if (!deleteItem)
        return false
      const { not_deletable: notDeletable = false } = form.value || {}
      if (notDeletable)
        return false
      return true
  })

  const _initItem = (resolve, reject) => {
    getItem().then(item => {
      form.value = { ...form.value, ...JSON.parse(JSON.stringify(item)) } // dereferenced
      resolve()
    }).catch(e => {
      form.value = {}
      reject(e)
    })
  }

  const init = () => {
    return new Promise((resolve, reject) => {
      if (isNew.value || isClone.value) { // new, use collection
        getListOptions().then(options => {
          const { meta: _meta = {} } = options || {}
          form.value = useItemDefaults(_meta, props, context)
          meta.value = _meta
          if (isClone.value)
            _initItem(resolve, reject)
          else
            resolve()
        }).catch(() => { // meta may not be available, fail silently
          form.value = {}
          meta.value = {}
          resolve()
        })
      }
      else { // existing, use item
        getItemOptions().then(options => {
          const { meta: _meta = {} } = options || {}
          meta.value = _meta
          _initItem(resolve, reject)
        }).catch(() => { // meta may not be available, fail silently
          meta.value = {}
          _initItem(resolve, reject)
        })
      }
    })
  }

  const save = () => {
    if (isClone.value || isNew.value)
      return createItem(form.value)
    else
      return updateItem(form.value)
  }

  const onClose = () => goToCollection()

  const onClone = () => goToClone({ ...form.value, id: id.value })

  const onRemove = () => deleteItem().then(() => goToCollection())

  const onReset = () => init().then(() => isModified.value = false)

  const actionKey = useEventActionKey(rootRef)
  const onSave = () => {
    isModified.value = true
    const closeAfter = actionKey.value
    save().then(response => {
      if (closeAfter) // [CTRL] key pressed
        goToCollection({ actionKey: true, ...form.value })
      else {
        form.value = { ...form.value, ...useResponse(response) }
        goToItem(form.value).then(() => init()) // re-init
      }
    })
  }

  const escapeKey = useEventEscapeKey(rootRef)
  watch(escapeKey, () => goToCollection())

  watch(props, () => init(), { deep: true, immediate: true })

  return {
    rootRef,
    form,
    meta,
    title,
    titleBadge,
    titleHelp,
    isModified,
    customProps,
    actionKey,
    isCloneable,
    isDeletable,
    isSaveable,
    isValid,
    isLoading,
    onClose,
    onClone,
    onRemove,
    onReset,
    onSave,
    confirmSave,
    services,

    // to overload
    scopedSlotProps: props
  }
}
