import { MetadataRoute } from 'next'

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: 'https://truetally.com',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: 'https://truetally.com/blocks',
      lastModified: new Date(),
      changeFrequency: 'hourly',
      priority: 0.8,
    },
    {
      url: 'https://truetally.com/about',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.7,
    },
  ]
}