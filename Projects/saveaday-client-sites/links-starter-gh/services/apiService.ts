import { ApiResponse, LinkPage } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://api.bigmints.com/api/v1';

export async function fetchLinkPage(slug: string, apiKey?: string): Promise<LinkPage | null> {
  try {
    const url = new URL(`${API_BASE_URL}/link-pages`);
    url.searchParams.append('slug', slug);
    
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
    };
    
    if (apiKey) {
      headers['X-API-Key'] = apiKey;
    }

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers,
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch link page: ${response.statusText}`);
    }

    const result: ApiResponse = await response.json();
    
    if (result.success && result.data.length > 0) {
      return result.data[0];
    }
    
    return null;
  } catch (error) {
    console.error('[ApiService] Error fetching link page:', error);
    return null;
  }
}
