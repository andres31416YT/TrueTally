import { getAuthHeaders } from '@/lib/api';

beforeEach(() => {
  localStorage.clear();
});

describe('api.getAuthHeaders', () => {
  it('returns empty object when no session exists', () => {
    expect(getAuthHeaders()).toEqual({});
  });

  it('returns auth headers from a valid session', () => {
    localStorage.setItem(
      'user_session',
      JSON.stringify({ email: 'user@test.com', role: 'admin' })
    );

    const headers = getAuthHeaders();
    expect(headers).toEqual({
      'X-User-Email': 'user@test.com',
      'X-User-Role': 'admin',
    });
  });

  it('handles malformed session JSON gracefully', () => {
    localStorage.setItem('user_session', 'not-json');
    expect(getAuthHeaders()).toEqual({});
  });

  it('falls back to empty strings when fields are missing', () => {
    localStorage.setItem('user_session', JSON.stringify({}));

    const headers = getAuthHeaders();
    expect(headers).toEqual({
      'X-User-Email': '',
      'X-User-Role': '',
    });
  });
});
