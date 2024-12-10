import { libraries } from '../_components/Chart'

export default [
  {
    name: 'Queue', // i18n defer
    groups: [
      {
        name: 'Redis Counts', // i18n defer
        items: [
          {
            title: 'Queue', // i18n defer
            metric: 'packetfence.redis.queue_stats_count',
            library: libraries.DYGRAPH,
            cols: 4
          },
          {
            title: 'Expired', // i18n defer
            metric: 'packetfence.redis.queue_stats_expired',
            library: libraries.DYGRAPH,
            cols: 4
          },
          {
            title: 'Outstanding', // i18n defer
            metric: 'packetfence.redis.queue_stats_outstanding',
            library: libraries.DYGRAPH,
            cols: 4
          }
        ]
      },
      {
        name: 'Redis Queue', // i18n defer
        items: [
          {
            title: `redis_redis-queue.memory`,
            metric: `redis_redis-queue.memory`,
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: `redis_redis-queue.net`,
            metric: `redis_redis-queue.net`,
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: `redis_redis-queue.commands_calls`,
            metric: `redis_redis-queue.commands_calls`,
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: `redis_redis-queue.keys`,
            metric: `redis_redis-queue.keys`,
            library: libraries.DYGRAPH,
            cols: 6
          }
        ]
      },
      {
        name: 'Redis Cache', // i18n defer
        items: [
          {
            title: `redis_redis-cache.memory`,
            metric: `redis_redis-cache.memory`,
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: `redis_redis-cache.net`,
            metric: `redis_redis-cache.net`,
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: `redis_redis-cache.commands_calls`,
            metric: `redis_redis-cache.commands_calls`,
            library: libraries.DYGRAPH,
            cols: 6
          },
          {
            title: `redis_redis-cache.keys`,
            metric: `redis_redis-cache.keys`,
            library: libraries.DYGRAPH,
            cols: 6
          }
        ]
      }
    ]
  }
]