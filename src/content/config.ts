import { z, defineCollection } from 'astro:content';

const blogSchema = z.object({
  title: z.string(),
  description: z.string(),
  pubDate: z.date(),
  updatedDate: z.date().optional(),
  tags: z.array(z.string()).default([]),
  draft: z.boolean().default(false),
});

const noteSchema = z.object({
  created: z.date().optional(),
  tags: z.array(z.string()).default([]),
});

export const collections = {
  'blog-zh': defineCollection({ schema: blogSchema }),
  'blog-en': defineCollection({ schema: blogSchema }),
  'notes': defineCollection({ schema: noteSchema }),
};
