import type { Metadata } from 'next'

const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000';

export const metadata: Metadata = {
  title: 'Acerca de TrueTally - Sistema de Votación Blockchain',
  description: 'Conoce TrueTally, el sistema revolucionario de votación electrónica basado en blockchain. Tecnología segura, transparente y verificable para elecciones democráticas.',
  keywords: 'acerca TrueTally, votación blockchain, sistema electoral, democracia digital, votación segura',
  openGraph: {
    title: 'Acerca de TrueTally - Votación Blockchain',
    description: 'Sistema revolucionario de votación electrónica basado en blockchain.',
    url: `${baseUrl}/about`,
    type: 'website',
  },
  twitter: {
    card: 'summary',
    title: 'Acerca de TrueTally - Votación Blockchain',
    description: 'Sistema revolucionario de votación electrónica basado en blockchain.',
  },
}

export default function AboutLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return children
}