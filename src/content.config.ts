import { defineCollection, z } from 'astro:content';
import { glob, file } from 'astro/loaders';

const posts = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/posts' }),
  schema: z.object({
    title:     z.string(),
    date:      z.coerce.date(),
    excerpt:   z.string(),
    cover:     z.string(),
    published: z.boolean().default(false),
  }),
});

const projects = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/projects' }),
  schema: z.object({
    title:       z.string(),
    category:    z.enum(['dla-domu', 'dla-firm']),
    images:      z.array(z.string()),
    description: z.string().optional(),
    year:        z.number().optional(),
    dimensions:  z.string().optional(),
    order:       z.number().default(0),
    published:   z.boolean().default(true),
  }),
});

const workshops = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/workshops' }),
  schema: z.object({
    title:          z.string(),
    description:    z.string(),
    duration:       z.string(),
    maxPersons:     z.number(),
    price:          z.number(),
    pricePair:      z.number().optional(),
    pricePairLabel: z.string().optional(),
    level:          z.enum(['fusing', 'podstawowy', 'zaawansowany', 'indywidualny']),
    setmoreUrl:     z.string().url(),
    active:         z.boolean().default(true),
    order:          z.number().default(0),
  }),
});

const testimonials = defineCollection({
  loader: glob({ pattern: '**/*.json', base: './src/content/testimonials' }),
  schema: z.object({
    name:    z.string(),
    content: z.string(),
    rating:  z.number().min(1).max(5).default(5),
    date:    z.string(),
    source:  z.string().default('Google'),
  }),
});

const vouchers = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/vouchers' }),
  schema: z.object({
    title:       z.string(),
    description: z.string(),
    price:       z.number(),
    buyUrl:      z.string().url().optional(),
    active:      z.boolean().default(true),
    order:       z.number().default(0),
  }),
});

const faq = defineCollection({
  loader: glob({ pattern: '**/*.json', base: './src/content/faq' }),
  schema: z.object({
    question: z.string(),
    answer:   z.string(),
    order:    z.number().default(0),
  }),
});

export const collections = {
  posts,
  projects,
  workshops,
  testimonials,
  vouchers,
  faq,
};
