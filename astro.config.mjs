import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightOpenAPI, { openAPISidebarGroups } from 'starlight-openapi';

export default defineConfig({
  site: 'https://mailapi.github.io',
  integrations: [
    starlight({
      title: 'Mail API',
      description: 'Vendor-neutral API specification for sending and receiving email.',
      plugins: [
        starlightOpenAPI([
          {
            base: 'api',
            schema: './openapi.yaml',
            sidebar: {
              label: 'Reference',
              collapsed: false
            }
          }
        ])
      ],
      sidebar: [
        {
          label: 'Overview',
          items: [{ label: 'Mail API', link: '/' }]
        },
        {
          label: 'API',
          items: openAPISidebarGroups
        },
        {
          label: 'Examples',
          items: [{ autogenerate: { directory: 'examples' } }]
        },
        {
          label: 'Compatibility',
          items: [
            {
              label: 'Protocols',
              items: [{ autogenerate: { directory: 'compatibility/protocols' } }]
            },
            {
              label: 'Clouds',
              items: [{ autogenerate: { directory: 'compatibility/clouds' } }]
            },
            {
              label: 'Frameworks',
              items: [{ autogenerate: { directory: 'compatibility/frameworks' } }]
            },
            {
              label: 'Languages',
              items: [{ autogenerate: { directory: 'compatibility/languages' } }]
            }
          ]
        },
        {
          label: 'Versioning',
          link: '/versioning/'
        }
      ]
    })
  ]
});
