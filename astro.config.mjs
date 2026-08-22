import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightOpenAPI, { openAPISidebarGroups } from 'starlight-openapi';

export default defineConfig({
  site: 'https://mailapi.github.io',
  integrations: [
    starlight({
      title: 'Mail API',
      description: 'Vendor-neutral API specification for sending and receiving email.',
      favicon: '/mailapi-logo.png',
      logo: {
        src: './public/mailapi-logo.png',
        alt: 'Mail API logo'
      },
      components: {
        Sidebar: './src/components/Sidebar.astro'
      },
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/mailapi/mailapi'
        }
      ],
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
        { label: 'Home', link: '/' },
        {
          label: 'Examples',
          items: [{ autogenerate: { directory: 'examples' } }]
        },
        {
          label: 'API',
          items: [...openAPISidebarGroups, { label: 'Versioning', link: '/versioning/' }]
        },
        {
          label: 'Implementations',
          items: [{ autogenerate: { directory: 'implementations' } }]
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
        }
      ]
    })
  ]
});
