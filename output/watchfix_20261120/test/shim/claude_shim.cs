// 가짜 claude (시험용 shim) — 실제 claude.exe 처럼 exe 로 빌드해 PATH 맨 앞에 둔다.
//  모드: 환경변수 KTS_SHIM_MODE
//   ratelimit_reset : "Claude AI usage limit reached. Your limit will reset at 3:00 PM" 출력 후 exit 1
//   r429            : "API Error: 429 Too Many Requests" 출력 후 exit 1
//   ok              : 인자 속 CLAUDE_RESULT_*.md 를 현재 폴더에 만들고 exit 0
//   hang            : 120초 대기(워치독 시험)
//   badflag         : --dangerously-skip-permissions 를 받으면 "unknown option" exit 1, 아니면 ok
//   resumefail      : --resume 을 받으면 "No conversation found" exit 1, 아니면 ok
//   fail            : 결과 파일 없이 "something went wrong" exit 1
//  --help : KTS_SHIM_NOSESS=1 이 아니면 --session-id / --resume / --continue 가 들어간 도움말
//  호출 기록: KTS_SHIM_ARGV 파일에 한 줄씩(--help 호출은 기록 안 함)
using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

class Shim {
  static int Main(string[] args) {
    Console.OutputEncoding = new UTF8Encoding(false);
    string mode = Environment.GetEnvironmentVariable("KTS_SHIM_MODE") ?? "ok";
    if (args.Length > 0 && args[0] == "--help") {
      if (Environment.GetEnvironmentVariable("KTS_SHIM_NOSESS") == "1")
        Console.WriteLine("Usage: claude [options]\n  -p, --print\n  --dangerously-skip-permissions\n  --permission-mode <mode>");
      else
        Console.WriteLine("Usage: claude [options]\n  -p, --print\n  -c, --continue  Continue the most recent conversation\n  -r, --resume [value]\n  --session-id <uuid>\n  --dangerously-skip-permissions\n  --permission-mode <mode>");
      return 0;
    }
    string log = Environment.GetEnvironmentVariable("KTS_SHIM_ARGV");
    string joined = string.Join(" | ", args);
    if (!string.IsNullOrEmpty(log))
      File.AppendAllText(log, DateTime.Now.ToString("HH:mm:ss") + " [" + mode + "] argc=" + args.Length + " :: " + joined + "\r\n", new UTF8Encoding(false));

    bool hasSkip = Array.IndexOf(args, "--dangerously-skip-permissions") >= 0;
    bool hasResume = Array.IndexOf(args, "--resume") >= 0;
    if (mode == "ratelimit_reset") { Console.WriteLine("Claude AI usage limit reached. Your limit will reset at 3:00 PM"); return 1; }
    if (mode == "r429") { Console.Error.WriteLine("API Error: 429 Too Many Requests"); return 1; }
    if (mode == "hang") { Thread.Sleep(120000); Console.WriteLine("hang done"); return 0; }
    if (mode == "fail") { Console.WriteLine("something went wrong"); return 1; }
    if (mode == "badflag" && hasSkip) { Console.Error.WriteLine("error: unknown option '--dangerously-skip-permissions'"); return 1; }
    if (mode == "resumefail" && hasResume) { Console.Error.WriteLine("No conversation found with session ID: x"); return 1; }
    string other = Environment.GetEnvironmentVariable("KTS_SHIM_PUSHOTHER");   // R8: 실행 도중 다른 PC 가 원격에 먼저 푸시한 상황
    if (!string.IsNullOrEmpty(other)) {
      var psi = new System.Diagnostics.ProcessStartInfo("cmd.exe", "/c git -C \"" + other + "\" commit -q --allow-empty -m other-pc && git -C \"" + other + "\" push -q origin main");
      psi.UseShellExecute = false; System.Diagnostics.Process.Start(psi).WaitForExit();
    }
    Match m = Regex.Match(joined, @"CLAUDE_RESULT_[A-Za-z0-9_]+\.md");
    if (m.Success) File.WriteAllText(Path.Combine(Environment.CurrentDirectory, m.Value), "# 가짜 결과 (shim)\r\n", new UTF8Encoding(false));
    Console.WriteLine("done: " + (m.Success ? m.Value : "(결과 파일명 없음)"));
    return 0;
  }
}
