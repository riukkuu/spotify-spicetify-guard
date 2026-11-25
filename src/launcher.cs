using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows.Forms;

public static class SpotifyLauncher
{
    public static int Main(string[] args)
    {
        string store = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "SpotifyAdBlock");

        try
        {
            string dir = AppDomain.CurrentDomain.BaseDirectory;
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
            if (!File.Exists(real))
            {
                MessageBox.Show(
                    "Spotify-real.exe is missing. The launcher cannot start Spotify.\n\n" +
                    "Run Uninstall.cmd from the package folder, then reinstall the package.",
                    "Spotify Spicetify Guard",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return 1;
            }

            var sb = new StringBuilder();
            foreach (string a in args)
            {
                if (sb.Length > 0) { sb.Append(' '); }
                sb.Append(QuoteArgument(a));
            }

            var start = new ProcessStartInfo(real, sb.ToString())
            {
                WorkingDirectory = dir,
                UseShellExecute = false
            };
            Process.Start(start);
            return 0;
        }
        catch (Exception ex)
        {
            try
            {
                Directory.CreateDirectory(store);
                File.AppendAllText(
                    Path.Combine(store, "launcher.log"),
                    DateTime.Now.ToString("s") + " " + ex + Environment.NewLine);
            }
            catch { }
            return 1;
        }
    }

    // Correct Windows command-line quoting: doubles backslashes before a quote
    // and before the closing quote, so paths ending in "\" survive intact.
    private static string QuoteArgument(string value)
    {
        var sb = new StringBuilder("\"");
        int slashes = 0;
        foreach (char c in value)
        {
            if (c == '\\') { slashes++; continue; }
            if (c == '"') { sb.Append('\\', slashes * 2 + 1); sb.Append('"'); }
            else { sb.Append('\\', slashes); sb.Append(c); }
            slashes = 0;
        }
        sb.Append('\\', slashes * 2);
        sb.Append('"');
        return sb.ToString();
    }
}
