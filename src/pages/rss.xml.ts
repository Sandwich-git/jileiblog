import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';

export async function GET(context: { site: string }) {
  const zhPosts = await getCollection('blog-zh');
  const enPosts = await getCollection('blog-en');

  const allPosts = [
    ...zhPosts.map(p => ({ ...p, lang: 'zh' as const })),
    ...enPosts.map(p => ({ ...p, lang: 'en' as const })),
  ];

  const publishedPosts = allPosts
    .filter(p => !p.data.draft)
    .sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());

  return rss({
    title: 'jilei.blog',
    description: '使用 Claude 的心得与技术分享',
    site: context.site,
    items: publishedPosts.map(post => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.pubDate,
      link: `/${post.lang}/blog/${post.slug}/`,
    })),
  });
}
