export default function SignInPage() {
  const handleLogin = () => {
    window.location.href = `/users/auth/google_oauth2`;
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 bg-slate-950 text-white">
      <h1 className="text-2xl font-bold">Time Bucket App サインイン</h1>
      <button
        type="button"
        onClick={handleLogin}
        className="rounded bg-white/10 px-4 py-2 text-white hover:bg-white/20"
      >
        Googleアカウントでログイン
      </button>
    </main>
  );
}
